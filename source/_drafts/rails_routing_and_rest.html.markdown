# Rails Routing

I'm annoyed with Rail's routing, I'm from England, in England when we're
pissed off with something we write a strongly worded letter, have a cup of
tea, and then simmer on it until we've developed enough new grey hairs.

## What I want

**I want Rails to generate routes in my models, I write clean, separated code
and sometimes I need URLs in a decorator, presenter or some backend process**

## Background

One of the important principles of REST is that the API should include all
relevant URLs in the responses, that's to say the client shouldn't have to
hard-code anything, except the domain name.

Here's an example of a good RESTful response body in JSON

``` js // HTTP/1.1 GET /examples/123.json { id: 123, name: 'I\'m a short
example', links: { 'self': { href: 'http://api.example.com/examples/123' }
'next': { href: 'http://api.example.com/examples/124' } } } ```

That isn't really debatable, it's used in [HTTP
headers](http://www.w3.org/TR/html401/struct/links.html#h-12.1.2), it's used
in correctly by a handful of [good](http://develop.github.com/)
[APIs](http://www.twilio.com/docs), and it's been talked about more than
enough.

REST is not just about which HTTP verb you choose to use, or keeping verbs out
of the URLs (although, those pointer are important too.)

**Note**, the key thing, the model knows where it is represented. The idea
that storage and urls are different is important in your application, but in
order to allow anyone else (even if that someone else is yourself) access the
data anywhere else, you have to treat the url and the representation as the
same thing.

## The view should care about formatting the model

This is partly true, but I would argue that preparing the model to go over the
wire (maybe the API is written in BSON, or MessagePack, maybe it's a binary
format) is not a view responsibility. There's nothing that says it's being
formatted when we send it to, or present it to an API client.

## Ahh, you said *presented* you need decorators/presenters!

That's absolutely true, incase you aren't familiar with the concept, the
`Decorator` or `Presenter` is a design pattern which wraps the object in some
container which is responsible for formatting behaviour. The classic
simplistic example might be a model such as:

``` ruby Demo = Class.new(ActiveRecord::Base) Demo.create!(name: 'Example
demo', date: '04-04-2004 04:04:04+Z', price: '123') ```

This is nothing special, notice the date has a timezone, and the price is in
minor units, we assume here that it's Euros, for the sake of argument.

One could format the price with `number_to_currency` everywhere you use it, or
more sensible people would write a decorator/presenter that looked something
like this:

``` ruby require 'delegate' class DemoDecorator

  attr_reader :demo delegate :id, :name, to: :demo

  include NumberFormattingHelper

  def initialize(demo) @demo = demo end

  def price number_to_currency(price) end

end ```

Here, in this instance we have't bought much, the decorator is really simple,
but this is the place you can put allll the logic about how Demos are
displayed in your application. I'm a big big fan of this technique, because
conceptually when writing software there's a strange duality that you don't
want the way you store something to affect how it is rendered, but the way it
is stored often dictates how it is retrieved, and thus what chances you have
to display it.

One massive win with the decorator pattern is the ease of testing, with stubs
and mocks, you can test all formatting logic without hitting any real
backends, and that's powerful.

### Did I sell you on Decorators, yet?

If not [thoughtbot have an excellent article that explains more about
presenters and
decorators.](http://robots.thoughtbot.com/post/20964851591/decorators-compared-to-strategies-composites-and)
If I've sold you, then keep reading.

## Decorators formatting JSON.

The problems we'll talk about here aren't exclusive to Decorators, they apply
everywhere that isn't a view. (Which in a backend-heavy application, is damned
near everywhere)

So we'd like to make the decorator responsible for rendering the model as
JSON, that's a smart move in my book, because the formatting will be
consistent, the JSON consumer can really benefit from the links that we send
back, and the whole thing can be used to build a really powerful rich &
responsive application.

So we try to implement `to_json` like this:

``` ruby class DemoDecorator

  # ...

  def to_json MultiJSON.encode(to_hash) end

  def to_hash { id: id, name: name, links: { self: demo_url(demo), next:
  demo_url(demo.next) } } end

  # ...

end ```

This blows up, `NoMethodError: undefined method `demo_url' for main:Object`,
so there's no URL helpers in your decorator, actually that's not all that
surprising, we could of course `include Rails.application.routes.url_helpers`
[this module from
ActionPack](https://github.com/rails/rails/blob/master/actionpack/lib/action_view/helpers/url_helper.rb)
actually isn't too bad, in the first instance it has a small number of fairly
well defined methods. The problems are two fold:

1. When you first use a route, the *url_helpers* class will define every
   `*_path` and `*_url` method defined in your `routes.rb` file, and it will
   define them in our *DemoDecorator*. Our *DemoDecorator* now has ~500
   methods (in my middle-trivial application)
2. Your class will err out with `ArgumentError: Missing host to link to!
   Please provide the :host parameter, set default_url_options[:host], or set
   :only_path to true` unless you define a method in your decorator called
   `default_url_options` which returns the same hash as is defined in the
   environment configuration, the same hash is made available in
   `Rails.application.config.action_controller.default_url_options`.

Things get much worse if you have to use `polymorphic_url_for`, which I
genuinely believe is evil, but I'm happy that it exists, as one of the models
in my application *may* or may not be nested under another (episodes of
television shows, which normally belong to seasons, but not always). I'll
mention more about `polymorphic_url_for` shortly.

## Solution?

The problems, first:

1. We don't want to poison a small well tested presentation class for one of
   our domain objects with methods pertaining to the urls for every
   model/feature of our application.
2. We don't want to define a method that returns the defaults that we already
   set. We don't want to do this, because we **already set the bloody
   defaults**.

The solution, actually is incredibly simple, I dropped the following into
`lib/routing_proxy.rb` (not initializers, as it isn't boot-up/configuration
code, this is important, my other classes rely on it.):

``` ruby class RoutingProxy

  include Rails.application.routes.url_helpers

  def default_url_options
  Rails.application.config.action_controller.default_url_options end

end ```

At first glance, and after a few hours of living with using it, it's not too
bad - we can now do the following in our decorator:

``` class DemoDecorator

   delegate :demo_url, to: :routing_proxy

   # ...

  private

    def routing_proxy RoutingProxy.new end

end

```

Incase the `delegate :method, to: :receiver` syntax, it's easy - it means when
we call `:demo_url` in our application, the delegator code takes care to call
that method on `routing_proxy`, so without polluting `to_hash`, the routing
methods are now called on a new instance of `RoutingProxy`.

### Shiny Happy Code

In the end, I'm happy with this solution, for a few reasons mostly it's clean
and there's one place that all routing in decorators travels through. Secondly
if that routing behavior ever has to change, I can implement those route
methods as real methods in my routing proxy, implement the logic as required,
and defer to the `url_for` method of the URL helpers for complicated logic, it
also has a massive secondary benefit. **Testing**, we can stub the
`RoutingProxy` methods for unit testing without having to defer to the Rails
stack. Naturally in integration and acceptance tests, we hit every component,
but being able to short-circuit URL generation for unit testing is a big win
in cleanliness and time.


## But wait a minute, `polymorphic_url_for`...

So `polymorphic_url_for` still won't work. This method is defined in
`ActionDispatch::Routing::PolymorphicRoutes`, again to use this in the
decorator we have the same problems as when including the URL helpers, except
`ActionDispatch::Routing::PolymorphicRoutes` has many fewer methods, so it's
slightly less toxic, but it has another problem which is that it assume
certain things about the context in which it is running.

`polymorphic_url` is separated from the rest of the URL helpers, because all
it does is infer when you meant when you wrote `polymorphic_url([User.first,
Demo.last]))` it figures that you wanted to write `user_demo_url(User.first,
Demo.last)` it then uses `send()` to call that method on the current receiving
object, so you can only use `polymorphic_url` in a class which already has all
the other URL helpers.

**Note:** That's not completely true.

There's a largely un-documented, difficult to figure-out, and
not-intended-for-this-purpose feature of the `polymorphic_url` method, that is
when give an instance of
[`ActionDispatch::Routing::RoutesProxy`](https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/routing/routes_proxy.rb),
it will call `send()` on that object, not on the current `self`, this feature
appears to be intended for easing the development of inter-engine routing in
Rails, but I didn't find much more than that about it. I also had to [read the
tests](https://github.com/rails/rails/blob/master/actionpack/test/activerecord/polymorphic_routes_test.rb)
to figure out how to use this class, which isn't ideal - but I'm happy that
the tests were there.

Here's how it works

``` ruby polymorphic_url([demo.user, demo]) # Where demo.user may be nil, so
we couldn't use user_demo_url() ```

In this instance `polymorphic_url` will call `demo_url()` on `self` (main
object, or your class, whatever) - this method shouldn't exist, because if
you've been following along, all those methods are in a `RoutingProxy` class
to keep namespaces clean.

The trick is to do something like this:

``` ruby adrrp =
ActionDispatch::Routing::RoutesProxy.new(Rails.application.routes,
RoutingProxy.new) polymorphic_url([adrrp, demo.user, demo]) ```

In this, correct instance `polymorphic_url` will call `demo_url` on the the
instance of `RoutesProxy`, this gives us what we need.

The [special
case](https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/routing/polymorphic_routes.rb#L91)
in the `polymorpic_url` implementation looks especially for an instance of
this class.

## What next?

I think that someone should examine making a single, useful Routing interface
for Rails, the *helper* methods are implemented in a module, and that could
easily become a class (or they could be exposed via a class, which is exactly
what I've built here). That would be a big win in the short term.

The defaults that we set could be honored throughout, I'm genuinely not sure
why this works the way that it does, but it's a little nonsensical to me,
defining a magically named method to return a hash that we already gave to the
framework really doesn't make sense to me.

For polymorphic_urls, I dare say that the same should happen, I'd like to see
a class upon which we could call methods such as `polymorphic_url` and
`polymorphic_path`, the class should take care of the routing proxy and
context.

## Rails is open source... just fix it!

I don't have time to get involved with taking this discussion to the Rails
core team, the last few issues I've been involved with have been largely
ignored and/or [bike
shedded](http://en.wikipedia.org/wiki/Parkinson's_Law_of_Triviality).  This
may say more about the kinds of issues that I report/run into than about the
Rails team, and Routing is a hot-topic. Unfortunately generating routes in
models is a classic hate-war topic, so I won't be getting involved.
