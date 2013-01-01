---
title: "The best description of a ruby fiber"

---

I'm thoroughly, utterly confused about Ruby 1.9's Fiber feature. Whilst
working on [Fern] we have a "windowing" function, this is essentially
user-controlled concurrency, and our existing, ugly as sin implementation
looks something like this:

    class Window < Common
      def perform &block
        hosts.each_slice(options[:max]) do |h|
          Parallel.new(h, options).perform &block
          wait
        end
      end
    end

The Parallel helper, not shown here is implemented using Threads, simple,
almost-real concurrency should be good enoguh for me in this context, the
performance of the host machine is unlikely to be the bottleneck in a remote
SSH command library, that said I've been wanting to learn more about using
Fibers for a long time and today happened upon [this article][1]:

> Execution of blocks and methods always begins from their first statement.
> Each time, their local variables are initialised anew. If they need to
> retain state across calls, they must do so explicitly, using either global
> variables or variables defined in their enclosing scope. A fiber—a
> lightweight, semi-coroutine—provides an alternative approach. It is
> effectively a block whose execution can be suspended—passing control back to
> its caller. The caller may subsequently resume the fiber from the point at
> which it was suspended. A fiber, therefore, automatically maintains state
> across calls: its local variables are initialised only the first time it is
> resumed. Only one fiber may execute at any one time, so, like threads, they
> merely create the illusion of concurrency.

> A Fiber object is created by passing a block to Fiber.new. The block is not
> called until the fiber is resumed.

> Resuming a fiber that has not been resumed previously, executes the block
> from the beginning. If the block opts to pass control back to its caller,
> the fiber suspends itself, and execution jumps to the statement following
> that which resumed the fiber. If this fiber is resumed again, it will
> continue executing its block from where it left off last time. A fiber may
> repeat this process as often as it likes.

> A fiber is resumed with Fiber#resume. It passes control back to its caller
> with Fiber.yield—which has no relation to the yield keyword. Any arguments
> supplied to #resume are passed to the fiber: if the fiber had not been resumed
> previously, they are passed in as block arguments; otherwise, they become the
> return value of the corresponding Fiber.yield invocation. Likewise, any
> arguments passed to Fiber.yield become the return value of the corresponding
> Fiber#resume invocation.

> When the block exits, the fiber dies. Attempting to resume a dead fiber causes
> a FiberError to be raised. This exception will also be raised if a fiber is
> created in one thread but resumed from another.

The key things that I took from this were that **`yield` and `Fiber.yield` share
<em>no common meaning</em>**, it's a classic case of unfortunate naming. Secondly **resuming a
Fiber will start un-resumed Fibers at the first statement, and
<em>yielded</em>
fibers at the place where they relinquished control.**

This makes reading the articles about fibers much easier, and in an example
such as the following begins to make sense:

    fib = Fiber.new do
      x, y = 0, 1
      loop do
        Fiber.yield y
        x, y = y, x + y
      end
    end
    2_000.times { puts fib.resume }

To go through it line by line,

1. Create a new Fiber, it won't run until something calls resume on it
2. Initialize some variables
3. Start a loop, this runs *forever*, but we break out as soon as we
    call `Fiber.yield` on the next line
4. Return from the Fiber block with the value of `y`, on the first
    run this sends `1` (`y`) as the return value of `fib.resume`,
    so we effectively `puts 1` on line #8.
5. Calculate the next values, this is standard [Fibonacci stuff].
6. (Nothing)
7. (Nothing)
8. Call the fiber 2,000 times, the fiber remembers the values of `x` and `y`
    between calls, and will begin from line #4 on all calls except the first.
    because of the infinite loop, control will return to line #4 which will
    exit the fiber, returning the latest number in the sequence to the caller
    on this line.

[Fern]:             http://www.rubygems.org/search?query=fern
[Fibonacci Stuff]:  http://en.wikipedia.org/wiki/Fibonacci_number
[1]:                http://ruby.runpaint.org/concurrency
