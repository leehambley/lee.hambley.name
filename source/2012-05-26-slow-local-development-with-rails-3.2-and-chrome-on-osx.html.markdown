---
title: Slow Local Development with Rails 3.2 and Chrome on Mac OS X

---
I've been seeing load times of 35+ seconds on OSX whilst using Chrome, and a local
development host using Rails on the latest Ruby (*1.9.3-p194*), with or without the [falcon
patches], and to a lesser degree the same with Safari and Firefox.

I'm using custom local hosts, that is not `http://localhost:3000` but something like
`http://example.com.local:3000`, the following line is in my hosts file.

    127.0.0.1 example.com.local

This has been fairly standard developer practice for as long as I can
remember, but lately I've been experiencing incredible loading times.

The time doesn't seem to "go" anywhere, `time curl` reportings something like

    time curl http://example.com.local:3000/  0.01s user 0.00s system 0% cpu 5.733 total

And the browsers hang for 20+ seconds doing almost nothing. The corresponding
Rails log line for this request was (I'm using [Foreman]):

    10:38:13 web.1 | Completed 200 OK in 429ms (Views: 200.7ms | ActiveRecord: 15.4ms)

I stumbled across a [suggestion related to Windows 7] running with IPv6
enabled (which is still not the default, as far as I am aware) can cause this,
as althoguh the host is available via IPv4, the system still attempts to
resolve the host over IPv6 first (it would appear)

Althoguh the suggestion was targeted at Windows 7, I had [tried] everything [else] and didn't
see that I had anything to lose by adding another couple of lines to my hosts
file, now that it looks like this:

    127.0.0.1 example.com.local
    ::1       example.com.local

It looks like if you are a Firefox user it might be possible to [disable
IPv6] in Firefox ([also poissible with Chrome]) , but frankly in 2012 this isn't a wise thing to
do, as the alternative (adding 1 line to your hosts file) is much wiser, and IPv6 isn't going
away, even if it isn't changing the world quite yet.

After making this change the resulting timed curl line looks like this:

    time curl http://example.com.local:3000/  0.01s user 0.00s system 2% cpu 0.683 total

So although this post is entitled *... and Chrome...*, there's clearly a win
to be had by correctly specifiying your local development hosts.

[tried]: https://github.com/wavii/rails-dev-tweaks
[else]: http://guides.rubyonrails.org/caching_with_rails.html
[falcon patches]: https://gist.github.com/1688857
[suggestion related to Windows 7]: http://stackoverflow.com/questions/1726585/firefox-and-chrome-slow-on-localhost-known-fix-doesnt-work-on-windows-7
[disable IPv6]: http://thedaneshproject.com/posts/disable-ipv6-in-firefox-3/
[also possible with Chrome]: http://superuser.com/a/174721
