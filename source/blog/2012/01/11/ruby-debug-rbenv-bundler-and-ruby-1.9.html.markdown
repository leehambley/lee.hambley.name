---
title: "Ruby-debug, Rbenv, Bundler and Ruby 1.9"
date: 2012/01/11
---

I had a rather difficult time to make this all work, without massive amounts of screwing around.

It seems the magical incantation is to install the regular MRI `1.9.3-p0`, without the build-patch recommended by so many (that is `-fvisibility=hidden`).

Then use the following Gist, to install all gems:

* <https://gist.github.com/1403066>

After that, download the same in your `vendor/cache` directory (or wherever your Bundler gem cache lives), and add something like the following to your Gemfile, I added it as a separate group, as there’s a few comments standing around, as I hope this process will improve in the near future, the changes I made to my Gemfile are standing in this gist:

* <https://gist.github.com/4a7bbfd8455cd06b7e8d>
