---
title: "Using Capistrano v3 With Chef"
date: 2013-06-11
---

We've been working really hard to push Capistrano v3, after years of
languishing behind the cutting edge, and in an environment where Chef and
Puppet (which should really restrict themselves to working on infrastructure)
encroaching on deploying applications, as well; I've been really happy to have
had the chance to code a really nice way bridge the gaps, and make Capistrano
work better with Chef for deployments where repeatable infrastructure is
important, but fast deployments of application code are essential, here's the
breakdown.

Capistrano v3 is built around Rake, so we can have `file` tasks as
dependencies of tasks, so we can do something like:

    file "cookbooks.tar.gz" => FileList["cookbooks/**/*"] do |t|
      sh "tar -cvzf #{t.name} #{t.prerequisites.join('  ')}"
    end

    namespace :'chef-solo' do
      desc "Package and upload the cookbooks"
      task :'upload-cookbooks' => 'cookbooks.tar.gz' do
        tarball = t.prerequisites.first
        on roles(:all) do
          execute :mkdir, '-p', '/tmp/chef-solo'
          upload!(tarball, '/tmp/chef-solo')
          execute :tar, '-xzf', "/tmp/chef-solo/#{tarball}"
        end
      end
      desc "Uploads host specific configuration for chef solo"
      task :'upload-host-config' do
        on roles(:all) do |host|
          template_path = File.expand_path('chef-solo.rb.erb')
          host_config   = ERB.new(File.new(template_path).read).result(binding)
          upload! StringIO.new(host_config), '/tmp/chef-solo.rb'
        end
      end
      desc "Upload cookbooks and configuration and execute chef-solo."
      task default: [:'upload-cookbooks', :'upload-host-config'] do
        on roles(:all) do |host|
          execute :'chef-solo', '--config', '/tmp/chef-solo.rb', '--log_level', 'info'
        end
      end
    end

There's quite a lot going on here, so let's walk through it.

First of all the `file` task has no namespace, even if it would be declared
inside the `namespace` block, there's no sense in that, so Rake ignores it.

The `file` task has a dependency on the results of a `FileList`. This mixture
will check the modification times on all of the files that match the pattern
on the `FileList`, and if any of them are newer than the `cookbooks.tar.gz`,
or if the `cookbooks.tar.gz` file doesn't exist at all, it will be packaged.

If the `FileList`'s matched files are all older than the `cookbooks.tar.gz`
file, then the dependency won't be built again, you could typically add this
file to a `.gitignore`, or make a point of checking it in (although in that
case, you might want to build that in a `pkg/` or similar directory to avoid
making a mess of your repository), that'll depend how often your Chef
dependencies change.

Next we enter the `:chef-solo` namespace, here we've defined three tasks, each
of which has a simple description, but we'll walk through them anyway.

The `chef-solo:upload-cookbooks` task depends on the cookbooks file, meaning
we can invoke this directly, and it'll build the cookbooks for us, no need to
remember to call that every time!

It then connects to all servers matching any roles (see the Capistrano
documentation) and uploads the cookbooks tarball into `/tmp`, where it is
unpacked. In a real production environment, you'd probably want to put it
somewhere other than `/tmp`, but I'll leave that up to you.

The next task `chef-solo:upload-host-config` does something pretty smart,
we're using ERB to generate a configuration specifically for this host, based
on the `host` object that Capistrano passes into the block, here's what that
template might look like:

    solo true
    log_level :info
    node_name "<%= hostname %>"
    cookbook_path   ["/tmp/chef-solo/cookbooks", "/tmp/chef-solo/site-cookbooks" ]
    data_bag_path   "/tmp/chef-solo/data_bags"
    json_attribs    "/tmp/chef-solo/node.json"
    role_path       "/tmp/chef-solo/roles"
    evironment_path "/tmp/chef-solo/environments"

Here the `hostname` method is called on the `host` object which we've passed
in, we could pass in the `binding`, rather than the host to access the `stage`
and or `environment`, if and when chef-solo ever supports those features, and
we'd still be able to access the current host.

This file is uploaded as a `StringIO`, this is a way to make sure we don't
even have to save the host specific configuration to disk on our workstation,
and it is uploaded directly from a variable to a file on each host saving
headaches.

The final `default` task can be run simply by doing `cap chef-solo`, which
will implicitly call `chef-solo:default` (another behaviour inherited from
rake). This task depends on the two which we've just talked about, they'll be
called every time, as there's no way for rake to know that the task has
already been run, or not. The `upload-cookbooks` task itself will then
guarantee that the tarball is new enough, because the FileList will be checked
for modifications.

Dependencies resolved, cookbooks bundled and uploaded, it'll finally execute
chef solo on each server in parallel.

This is a great prefix to the typical `cap deploy`, and indeed there's no
reason tasks like this can't exist along side your regular `Capfile`, if you
want to deploy chef solo as a dependency of every `cap deploy`, you can easily
do something like:

    task 'deploy:default' => 'chef-solo:default'

This re-opens the `deploy:default` task, and defines upon it another
prerequisite task, the chef-solo stuff, meaning before any deployment, we'll
always deploy the latest chef solo recipes!

Whoohoo, that didn't hurt too much, and we didn't have to sell our soul to
OpsCode!
