---
title: Processing a streaming API with Ruby sockets without Net::HTTP

---
I recently ran across the use-case of needing to consume the [CouchDB `_changes`
stream](http://guide.couchdb.org/draft/notifications.html#continuous) in a streaming fashion.

Most of the recommendations I found online were singing the praises of
EventMachine or some other event-driven solution, but in fact, it's much
easier than that, here's the code I came up with:

    require 'json'
    require 'thread'
    require 'socket'

    changes = Queue.new
    reader  = Thread.new(changes) do |changes|

      s = TCPSocket.new 'localhost', 5984
      s.write "GET /omio_development/_changes?since=0&feed=continuous\r\n"
      s.write "\r\n"

      while line = s.gets
        changes.push JSON.parse(line) if line.chars.first == '{'
      end
      s.close
      changes.push NilClass

    end

    handler = Thread.new(changes) do |changes|
      while change = changes.pop
        break if change.is_a? NilClass
        warn change.inspect
      end
    end

    [reader, handler].map(&:join)

This is the simplest thing that can normally be made to work, and is idiomatic
using Ruby's `Queue` class (imported from the *thread* part of the standard
library) to communicate between two threads.

There's nothing groundbreaking here, it should probably be moved into a class,
and made so that it can be started, and stopped from the background (I'd run
these two threads in a new thread, that a
start and stop method could be called easily and conveniently. I'd probably
pass a locked mutex to the reader thread to stop it in the first line of it's
body before calling `start` on my class, the second thread wouldn't need a
mutex as it would block immediately on the handler

I've taken some liberties here, with the specifics of the couchdb continuous
changes protocol, as I simply dont' care about the HTTP headers (they'd tell
me it's a chunked response, with no `Content-Length`.

It would be prudent to test this a bit more thoroughly, but writing a
test-case for this would involve writing a server as well, as I'm not aware of
any of the web-mocking tools that will allow you to mock streaming bodies, but
I haven't researched it extensively.

There's probably a better way of signalling the handler thread that the queue
is finished than passing a `NilClass`, curiously in Ruby there's no way to
*close* a queue, or terminate it, except to send a known *end of queue* value
to cause the thread to break out. In the *Go* language, queues are called
*channels* and they can be `closed()`, signalling anyone who is reading the
channel that there's nothing else to read, and never will be.
