---
title: Dirt simple StatsD server for local development

---

We instrument quite a lot of our code, especially with [StatsD]. It's so easy to
implement, it's basically a no-brainer. The overhead of the [UDP packets] is so
low that you can afford to instrument pretty much everything.

There is one pretty large mental investment cost centre though, which is what
to do about collecting, graphing, logging, rotating, storing and analysing all
the collected StatsD data.

Those questions are best answered in production (we like [collectd],
[Graphite] with the [Graphene] frontend) by your Ops team.

To simplify local development, I wanted something so that I could see my
instrumentation easily in the console, whenver I thought that I might need it:

<script src="https://gist.github.com/leehambley/5186145.js"></script>

We use [foreman] for most development projects and thus we save this little
script as `./bin/statsd`, change the mode to `+x` so that we can run it, and
add this line to our `Procfile`

    statsd: ./bin/statsd

The `term-ansicolor` gem makes the statsd lines standout really clearly, and
we can rest assured that in the production environment that nothing bad will
happen because of different logging configs.

[statsd]: https://github.com/etsy/statsd/
[UDP packets]: http://en.wikipedia.org/wiki/User_Datagram_Protocol
[collectd]: http://collectd.org/
[Graphite]: http://graphite.readthedocs.org/en/1.0/overview.html
[Graphene]: http://jondot.github.com/graphene/
[foreman]: https://github.com/ddollar/foreman
