---
title: "Seven Years Under A Palm Tree"
date: 2016-04-24
---

![Our old logo, so easy you can be on the beach!](/img/2016-04-24-seven-years/capistrano-logo-big.png)

The last time I wrote on this blog was June 2013 as I geared up to launch
Capistrano v3 which was a complete ground-up rewrite. The rewrite had been
"finished" and working for a while, but given that it was a ground-up rewrite
in the spirit of Capistrano, but shared nary a single line of code with it's
forebear the release dragged up a bunch of mixed emotions, was Tom and I being
frauds writing new software and releasing it under an existing "brand name", or
was it a violation of some unwritten Netiquette - what right did we have to
make that decision in any case?

Today I'm reflecting at the end of a weekend where many things seem to be
aligning. My son is 18 months old today, my company [Harrow.io][1] (more below)
will release it's Capistrano integration on Monday, and one of the most
significant releases of Capistrano since the rewrite in 2013 will be released.

Serendipitously this also marks seven years to the week since my first commit
in Capistrano core landed, [trivial as it was][2]. Before I ever had code in
Capistrano I'd spent countless hours working to help people in IRC, and on the
then infantile StackOverflow (it was less than a year out of beta!), I'd also
written the tremendously popular `capistrano-handbook` which I finally uploaded
to Github on the same day that my code landed in Capistrano. I don't recall
those two miletones being related, apparently it was just a coincidence!

Capistrano 3.x, as brutally different thought it may have been was incredibly
well received, through the rewrite we lost thousands of lines of custom DSL
code, gained a lot in speed and pluggability and an immeasurable amount in
*maintainability*. Of course we also quietly dropped some seldom used features
and added them back as people identified a will to upgrade but noticed
something lacking.

So, tomorrow (2016-04-25) I'm [releasing Capistrano 3.5][3] which includes
tonnes of new features, nearly all community contributed and some that will
really, really help us to deliver more, better improvements in the future and
help us clean up some of the lingering issues about inaccurately written
documentation that predates Capistrano 3.x which confuses people. Matt's [`cap
doctor`][4] command will report unused variables, out of date plugins, list the
resolved variables for a given stage, etc. We're excited about this, it was
great achievement of Matt's to get that into 3.5!

Another huge part of Matt's work is the change to [the default Capistrano
output formatter][5]. This will likely be as controversial as the original
rewrite, it's inarguably better looking, more concise and easier to pick the
important information out of, but people can be resistant to change, so it's
super easy to set back to the previous `pretty` formatter!

**Another important part of the 3.5 release is the integration with
[Harrow.io][1].** Harrow is a platform, service and company that I founded with
some friends to make my work on Capistrano more sustainable by making it into
my day job. We built something that you can understand as being a "Continuous
Integration" tool but with a really distinctly different design to anything
else you migth have come across.

It's designed to feel like *a web-enabled extension of Capistrano's principles*.
With stages, and sets of environment variables, designed to make the tooling it
wraps better, faster, and easier to use.

Like most things I've contemplated doing with Capistrano over the years, not
least rewriting it from scratch, the decision to promote Harrow from within
Capistrano was not taken lightly, it's important to strike the right balance
between offering people a better experience with their software, without
forcing them into something they might come to resent.

The scope of the Capistrano/Harrow integration is a simple in-terminal prompt
(well behaved, presuming "no" if no answer is given within a few seconds or no
facility to prompt is available) when running `$ cap install` which happens
once and only once per project. We may expand the scope of this integration in
the medium-term future depending on the community feedback. The integration
does make one anonymous HTTP request to allow us to toggle things `off` incase
things go badly, which can be opted out of by simply setting `$ git config ...`
which will stop the integration doing *anything*. (We designed the integration
to be *so* discreet that *it doesn't even write a dot-file with
configuration!*)

![A screenshot of the integration](/img/2016-04-24-seven-years/integration-screenshot.png)

**Capistrano will always remain open source and [liberally licensed][6]**. Harrow
is closed-source (for now) platform with a cloud subscription model, and an
on-premise "enterprise" version which are offered as paid commercial services. With that
said, I'm still curious to see how the community reacts.

---

[1]: https://www.harrow.io/
[2]: https://github.com/capistrano/capistrano/commit/0713ae6d4d2b5b0cb801d494123af5cf6199b717
[3]: https://github.com/capistrano/capistrano/milestones/3.5.0
[4]: https://github.com/capistrano/capistrano/pull/1642
[5]: https://github.com/mattbrictson/airbrussh
[6]: https://github.com/capistrano/capistrano/blob/master/LICENSE.txt
