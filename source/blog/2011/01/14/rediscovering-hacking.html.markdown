---
title: Rediscovering Hacking
date: 2011/01/14

---

I’ve always told people that I’m a Hacker; anyone in the computer
industry should know what that means (and, here’s a hint, it doesn’t
mean **criminal**.)

I’ve always chosen the moniker Hacker because I’m not a programmer or an
engineer, or even a developer, pick any of the other suitably business
sounding job titles… and that’s not how I self-identify.

As a Hacker, I think years of having a serious job title "Platform
Developer", "Manager Software Engineering", etc has clouded my
judgement, it’s made me start talking about risk, and speaking about
features as "n-Days man-time" not "a few hundred lines of code".

I’ve stopped working on untested code, this might be a good thing, but
I’m not doing it because of a religious regions, or because hackers
don’t like crappy code, I’ve done it to dodge work, and cover my ass,
corporate style - this needs to change.

A friend recent linked me to [Duct Tape Programming] by Joel Spolsky, I
remember I used to be that guy, I used to hack for a 50% solution, and
patch up holes later.

I’m working (as many of those close to me) on a project which in
addition to a complex web application (which is home turf for my skills)
requires a piece of companion software running natively on the user’s
desktop. This has to be built in a mixture of C, C++ and Objective-C -
three languages I don’t really know that well (I can read the syntax,
and the code, but I’m not comfortable working in them) - It also
requires OpenSSL (security), ØMQ (messaging), libJSON (data transport) -
another three complex libraries I’ve never used.

My response was to buy [all][1] [the][2] [books][3] I could possibly find on the
related topics… and read them, instead of hacking.

After a good kick in the rear from [@paukul] - I spent some free time when
I returned to the UK hacking on the companion code, and I mean hacking.
I tried 200 things to make some obscure C/C++ bridge (which I now
realise is simple) work, because I didn’t have a choice, I was hacking
at my Gran’s place, in the Car, and on a Plane - there’s no way you can
sit with a book in this situation, you have to just go for it!

As a result, after three days, out of the 9 months I’ve been
researching, and background reading - I have more working than I could
have imagined… sure - it’s basically a cross-platform build, of some
software I don’t fully understand, and I don’t know precisely why some
of it is working; but it doesn’t matter.

I’m not trolling through life to build perfect software, I should aim to
build useful software, and build-in the stability later. To that end, my
project right now doesn’t compile on Windows, doesn’t deal with all
characters in file paths, and probably a bunch of other things I’ve
missed.

But that’s not important, this project is supposed to be a product, and
there’s more than 100 people signed up to beta-test it, and it’s going
to be free… so there’s basically no risk to getting something wrong.

I’m still not resolute about the route I took, on the one hand a lot of
reading, and planning, and design thinking has helped, I have a pretty
strong foundation, which is paying dividends now, but I’ve also got no
evidence that I even needed it. Interestingly, the more work I do - the
more this project looks like 5 individual projects, which is something I
hadn’t expected… but it’s moving so quickly, it’s changing every few
hours.

I’m lucky to have a free-day every week, one day every week I can spend
working solely on this, and I even have the use of my private office at
work on these days. It’s a great space, with a couch, a fatboy, and a
couple of desks, and walls soon to be covered in posters, emacs cheat
sheets, and diagrams of software nonsense my colleagues don’t
understand.

I can’t wait… a messy, informal space to do great work, fast, with
enough safety not to risk the business, or my job, and enough free time
to have a clear mind, and balance work, play and hacking, all in one
space.

[@paukul]: http://twitter.com/paukul
[Duct Tape Programming]: http://www.joelonsoftware.com/items/2009/09/23.html
[1]: http://en.wikipedia.org/wiki/The_C_Programming_Language_(book)
[2]: http://www.amazon.com/Large-Scale-Software-Design-John-Lakos/dp/0201633620
[3]: http://man7.org/tlpi/
