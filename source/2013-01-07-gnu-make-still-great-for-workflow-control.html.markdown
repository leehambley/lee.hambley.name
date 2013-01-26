---
title: GNU Make, still great for workflow control

---
You might think that GNU's *Make* is a tool for unix beards to compile the C
programs that you can't read, and never seem to work for you, but there's a
chance you've heard it's also pretty good for so-called workflow control.

One of the key things about Unix was supposed to be that everything is a file,
and as a result a lot of things input, and output files as their native
language, we can use this to our advantage, given the following problem:

 1. We need a SQL file from the web, it's gzipped (and for some reason it's z7
    zipped, but with .tar.gz file extension!).
 2. We should grab it if we don't have it already, and verify it's signature.
 3. We should unzip it.
 4. We should then import it to the SQL server.
 5. We can then run our job on it.

We could solve this with some shell-scripting, or some *if-else-etc*
constructs, or - we could better rely on *make* to guarantee all these things
happen.

**Make will recognise that a prerequisite exists already, and will skip that
step of the workflow, if it does not need to be performed again**

That means, when you've waited once for the download to complete (see code below),
once that file exists, you can re-run `make`, which will recognise that the
file already exists and skip that step.

Here's a sample `Makefile` from one of my projects:

    import: | import-sample
    download: data/latest-seed.sql

    import-sample:
      @./import.sh 150

    import-all:
      @./import.sh

    clean:
      rm -rf tmp/*
      rm -rf export/*
      ./bin/clean_db.sh

    data/latest-seed.sql: tmp/June-16-2012.z7
      @mkdir -p $(@D)
      @7z e $< -so > $@

    tmp/latest-seed.z7: tmp/latest-seed.rar
      @cp $< $@

    tmp/June-16-2012.rar:
      @mkdir -p $(@D)
      @curl "http://www.example.com/latest-seed.rar" -o $@

    .PHONY: import-all import import-sample clean download

A breakdown, lines with no indentation define *targets*, anything after the
semi colon defines a target that must be built before we can built this target
(which may in turn define it's own prerequisite targets).

The lines beginning with indentation are implementation lines, the `@`
swallows the shell output.

The mixture of `@D`, `$@`, `$<` and friends are various [automatic
variables][make-automatic-vars],
they refer to parts of the definition, so that we can reuse them, the
documentation isn't too difficult to read, but the ones I've used here are

<dl>
  <dt><code>@D</code></dt>
  <dd>The <em>directory</em> part of the task name. (if any)</dd>
  <dt><code>$@</code></dt>
  <dd>The name of the prerequisite.</dd>
  <dt><code>$&lt;</code></dt>
  <dd>The name of the target's first prerequisite.</dd>
</dl>

With the details out of the way, it's worth noting that you can also pass them
to any shell commands, in Makefiles you have to use the syntax `$(shell
.......)` to shell out, as `$(..)` is the variable syntax.

That said, one could shell out to `sed`, `awk` and friends with `$(shell
...)`, wherein any variables as noted above will be available.

**Note:** I didn't need to export any environmental variables here, but if I
did, the syntax is that they have to be written at the top of the file
(usually) and they shoul have the syntax `RACK_ENV := development`, or
something, for comparison that would be `export RACK_ENV=development` if you
did it in a shell script. Again, the distinction between the usual way, and
the Makefile way is because of Make interpreting the syntax we usually
associate with shell scriping in it's own way.

The first target line looks a little strange, the `<target>: | <prereq>`,
(empasis on the pipe) syntax means this is an *order only* depednency it
doesn't have any file-output that should be checked, it's just a task,
something that will always need to be done. That way, if all file prerequisites
are called `make` will run run the shell script.

The last thing that's unusual about this makefile is a relatively marge number
of `.PHONY` tasks. The `.PHONY` directive shows make that all the following
tasks are *always invalid* and always need to be run again. This way `make
clean` will always run regardless of any of make's own inferences of what
ought to run.

In summary, this workflow has saved me a lot of time, and whilst tools such as
Rake (Ruby make) might fit better into my workflow, I often use make to grab
seed files, to unpack, verify, sign and check files which are very often fed
into Ruby, or Go language programs. Make is an excellent way to do dependency
driven shell scripting, and it absolutely has a place along side other tools
in your stack. I used use makefiles to prepare the environment for my Go
programs to run. (Infact, in the example above the import.sh makes some SQL
schema changes that I couldn't script into Make, and then runs a go program to
export the data as JSON which my Ruby app expects, talk about <del>Rube
Goldberg</del> being a polyglot!

Make has a lot more to offer than you might expect, but it is also cursed with
a LOT of magic, such as how an empty makefile in a directory of C (and other
languages) will do the right thing, based on decades of magic that has been
baked in, somtimes reading someone elses makefile can be challenging, when
there's magic you didn't know existing running for reasons you don't
understand in a language you aren't familar with, it can be challenging, but
it's a handy tool for directing workflow non the less, and it's very
approachable, just don't expect to get much out of other people's rakefiles.

Hat-tip to Ted Dzubia, who blogged about this back in Febuary 2011, and
inspired me to embrace Make along side all my higher-level, and more modern
tools.

Ted took down his blog following a personal change of heart in 2012, but he
was kind enoguh to grant someone permission to mirror the site, and you'll
find the post that inspired me at:

 * [http://widgetsandshit.com/teddziuba/2011/02/stupid-unix-tricks-workflow-control-with-gnu-make.html][ted-dzubia]

[make-automatic-vars]: http://www.gnu.org/software/make/manual/html_node/Automatic-Variables.html
[ted-dzubia]: http://widgetsandshit.com/teddziuba/2011/02/stupid-unix-tricks-workflow-control-with-gnu-make.html
