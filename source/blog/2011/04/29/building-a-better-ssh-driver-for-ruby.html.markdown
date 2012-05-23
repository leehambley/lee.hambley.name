---
title: "Building a better SSH driver for Ruby"
date: 2011/04/29
---

I’ve been maintaining Capistrano for a long time now, and most of the
issues that hold me back from really improving the software boil down to
the simple proposition, it’s not possible to test a deployment in any
sane way. Part of this is down to the limitations of people’s
understandings of how this should work, and part of is it about having a
fast enough, capable enough SSH driver to hide a lot of the
behind-the-scenes work, and make sure we have a sane, predictable
environment, and take steps if not.

As a result, I’ve started work on a C-binding library for libssh.
There’s a few good reasons to link against a C-implementation, chiefly
amongst them are speed, and accuracy, and the ability to let the experts
build the really hard-core stuff, and concentrate on building a good
library for people to do work in Ruby.

My library will be named “libssh.rb”, and is hosted at the exceptional
GitHub.

Yehuda Katz, whilst he has made a faux pas or two in his community
management of bundler does make a good point… at Arrrr Camp he said the
“most” important thing is that the software be easy to use. He’s Right.

Can anyone honestly say they know when to use “ssh_options[:pty] = true”
with Capistrano, and what effects is has? Or what the “askpass” program
really is; or when to use it, how to configure it or more? I’d guess
not…

The truth is, most people don’t want to know how SSH works… they just
expect it to… so into the mix come a lot of paradigms missing and/or
unclear in Net::SSH… environmental variables (done right, configured in
the background channels), PTY and TTY allocation, in a sane and
transparent way, and proper handling of connection pooling and
negotiation, not to mention proper use of the key-agent for those with
passworded (that’s all of you… right?) keys.

I’ll be blogging a little more about each of these topics, and working
whenever I have the time towards releasing an SSH driver strong enough
to build the next version of Capistrano on top of, in the mean time
here’s a preview of how the DSL might look for working with SSH via
Ruby, backed by the most secure, and fully-featured C-implementation of
SSH.

<script src="https://gist.github.com/d5a67911bf39c5b2ff2a.js"></script>

Naturally, this is pretty
up in the air right now; one of the significant hurdles for me, is how
to test this in a sane way… I’m going to try following Mall Cop’s
example, in spawning a local SSH server, except I’m going to do it with
DaemonController, so that I have a little more say over how it should be
started, and stopped… and can specify various configuration files to
test behaviours. I also plan on using the Parallel gem, or at least a
compatible API, so that decent threading behavior can exist on all
platforms, in addition to using SystemTimer on platforms which require
it.

I don’t know a thing about Event Machine, so I can’t say there’ll be an
“em-libssh.rb”, but maybe someone could help me out and tell me what
pitfalls I should avoid in order to allow someone a little smarter than
I to contribute an EM-implementation for those who really need
performance.

Along the way I’ll be reaching out to Wayne E. Seguin, author of RVM, to
see what can be done to make using RVM over SSH easier… and along the
way I’ll take patches, help, advice and criticism from anyone with an
opinion and a text-editor.

So, in summary, the more, better feedback I get, the quicker this
project will come to fruition, the sooner we’ll have better, more
reliable remote-management tasks, and the sooner I can implement all the
things I’ve learned, to bring an exceptional experience to Capistrano
users, by releasing another major version, something worthy of Jamis’
contributions to this field.
