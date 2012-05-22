---
title: "`friendly_id` and parallel processes"
date: 2012/02/27
tags: ruby, rails, redis
---

I've been using `friendly_id4` for a while now and noticed that it doesn't have a guard to ensure that processes to not race to generate the *next* slug when collisions occur.

To that end, I submitted [a patch](https://github.com/norman/friendly_id/pull/243) that should clean up their internal API, and make it simper to override. I've written my own driver which uses Redis to store the unique key, looking it up the first time using the `friendly_id` built-in mechanism.

In this post I share my code, and explore some of the reasons for the design, as well as explaining what causes the processes to race, and how we can guard against that.

But there's a problem, they took out the feature which, was slightly too complicated, not needed by everybody, and was an extra installation step, even if you didn't need it.

That feature was a race-proof unique slug generator. For most people, looking to turn Their `<#Thing id=123 name="Test Thing!">` into a nicer looking url than `/things/123`, into something like `/things/test-thing`, there's no race condition.

## How it was always supposed to work... ##

If one tries to create another entry with the same `name` attribute at any other time, perhaps a few minutes later, `friendly_id` will generate the slug `test-thing--2`, which is perfect, mostly. The database has a guard on the `slug` column, ensuring that it remains `UNIQUE`, and multiple entries might have the same name, but they'll have a different slug, and thus, a different URl, nothing shocking so far.

## So... race condition? ##

The race condition happens when two processes (people, threads, processes, import tasks, whatever) try to create an entry with the same name, at the same moment. Here's what they both do, assuming the following existing data:

~~~ text
# Things table structure
id | title      | slug
---+------------+------------
 1 | Test Title | test-title-1
 2 | Test Title | test-title-2
 3 | Test Title | test-title-3
 4 | Test Title | test-title-4
~~~

1. Both processes will look at the data.
   **Both processes will find 4 records.**
2. Both processes will look at the last item.
   **Both processes will find `test-title-4`.**
3. Both processes will break off the existing `--{n}`
   **Both processes will assume the *slug sequence* is currently at `4`.**
4. *(Both processes will be **right**)*
5. Both processes will increment `n` number, to get the next number in the sequence.
6. Both proceses, assuming they have generated a safe slug, will save the new record with the (invalid) slug `test-title-5`.
7. **One of the processes will fail, because the database's `UNIQUE` constraint will be violated.**

FriendlyId v3.x prevented this by keeping the *slug sequence* in a separate place in the database, and operating upon it within a transaction, thus guaranteeing atomic access to reading, incrementing, and updating the *slug sequence*.

## The Problem ##

So, the problem is since `friendly_id v4`, the gem no longer guarantees two really important principles:

1. No guarantee that we're the only person reading this value, right now
2. No guarantee that the ID we'll choose will be unique a few µseconds from now.

## The Solution

The solution has a couple of important points, the first is that I've decided to use Redis, Redis is a technology with the real ability to polarize developers. My position: Redis is already in my stack, it has auto expiring keys (you'll see why...), and has safe, fast atomic operations on incrementing integers. Nothing else in my stack has those properties, not even a database sequence.

### Guarantee that we're the only people reading this value, right now.

Because of how I chose to solve this, this part of the problem is slightly turned on it's head. Because we are using Redis, we can normally skip reading the database, and read directly from Redis, except when the *slug sequence* doesn't already exist, and we have to create the first, or *seed* value.

The naïve implementation of this, from the current `friendly_id` `SlugGenerator` uses a snippet of SQL to read the database.

To ensure that we're the only people *reading* the *database* would require a table lock.

Locking the whole database means that even the web application process can't read that table, which probably means that your site will go offline for the duration of the lock. **This is why `friendly_id` no longer ships with this feature.**

To solve the *seed value* problem I elected to use a different kind of lock, a simple Redis key. To do that, before searching for the sequence value from the database, we create a certain key in Redis, this key represents our lock, if another process tries to create this key, it will fail, and as long as this key exists, our Ruby processes will not continue.

One risk with locking, is that if you fail to release the lock for any reason, the system remains blocked indefinitely; Redis hands us another tool *auto expiring keys*, which guarantee that we don't hold the lock for ever, and that in the event that we crash, or fail to release the lock, Redis will remove it for us in a few seconds.

Further to that, to ensure that we never block one process for a particularly long time (for example in reading the `last slug`, in case that our database is **very** slow, I used the `Timeout` library from the standard library. Because of how it's being used here, this **should** also be safe for Ruby 1.8.x.

### Guarantee that the sequence members we generate will be unique. ###

So, solving the *how to calculate the next slug sequence* problem. This is #2 from our problem list above. We can safely make two assumptions:

1. As long as we start with the right number, Redis will never give us back the same number (*slug sequence*) twice.
2. Our processes shouldn't fail too often (save, perhaps for validation errors, outside the scope of this problem), so we won't end up sky-rocketing the *slug sequence* by reading, and thus incrementing the slug sequence value in Redis.

As a counterpoint to *#2*, Redis is capable of storing *ver* large numbers. The documentation for INCR notes that Redis stores this internally as a string, (because Redis does not have an integer type) which is understood to represent a 64 bit signed integer. The maximum positive value of which is `(2^63)-1`, or *9,223,372,036,854,775,807*, or if you prefer **9 quintillion, 223 quadrillion, 372 trillion, 36 billion, 854 million, 775 thousand and 807**

## Testing

The integration tests exist in my own application which recreate the race, appears to be happy with this implementation, but it can surely be improved. There are some trivial unit tests in the Gist (linked below).. you can run these by ensuring you have `redis` and `minitest` installed, are running on `Ruby 1.9x`, and have started a redis-server with at least 10 databases (16 is the default) running on the default port (`6379`). Then simply invoke the tests from the command line:

~~~ sh
$ ruby ./the-contents-of-the-gist.rb
~~~

Or, if you really want to make sure it's tortured:

~~~ sh
$ for i in {1..100}; do; ruby ./the-contents-of-the-gist.rb; done
~~~

## Can I use this?

**Note:** You will need to use a version of `friendly_id` containing at least [this commit (`9ca0cf`)](https://github.com/norman/friendly_id/commit/9ca0cf294e5384bbca252167d276e1315517b650), at the time of writing that means HEAD, as it's not formerly been released yet.

Yes, if you can use MIT licensed software (see below), and your `Rails.application` instance defines a `redis` method, which returns an instance of a redis client, sure you can! If it doesn't, you can make it do so by dropping this in an initializer:

You can of course modify my code to rake Redis from somewhere else, make it's own connection, or whatever you want, really.

~~~ ruby
module ApplicationWideRedis

  extend ActiveSupport::Concern

  module ClassMethods
    def redis
       @redis ||= begin
        # You could also use Redis, without namespace here
        Redis::Namespace.new("my-app", :redis => Redis.new)
      end
    end
  end

  def redis
    self.class.redis
  end

end

Rails.application.class.send(:include, ApplicationWideRedis)
~~~

## Show me the code...

Improvements, suggestions, etc - send them all the Gist, comments, forks, changes, anything:

* https://gist.github.com/c014dfcc24f80f803621

## What other solutions might exist?

Plenty, actually - but mostly Redis solves this quite beautifully, and as I said at the top of this article, it's already in my stack, it's *very* fast, and *very* good at atomic operations, why not use it!

For some more discussion please see the issues/pull requests at Github /FriendlyId where I (`leehambley`) was involved in the discussion:

* https://github.com/norman/friendly_id/issues/243
* https://github.com/norman/friendly_id/issues/200

## Are you Crazy?

Norman Clarke, the `friendly_id` author said that using Redis for something that your RDBMS is good at is insane, and he might be right. But this solves the problem for me, and redis is already being used as a cache store, key store, score and summary store in my application, and the table locking and other solutions simply didn't work for me.

## License

This code is released under the [MIT License](http://en.wikipedia.org/wiki/MIT_License):

~~~
Copyright (C) 2012 Lee Hambley <lee.hambley@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
USE OR OTHER DEALINGS IN THE SOFTWARE.
~~~
