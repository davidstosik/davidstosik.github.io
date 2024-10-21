---
title: Deploying Writebook with Kamal 2
date: 2024-10-21 18:13:54.170920000 +09:00
category: dev
---

[Writebook](https://once.com/writebook) is [37signals](https://37signals.com/)' second ONCE product.

It is a free book publishing tool based on Ruby on Rails, distributed by 37signals under their [ONCE](https://once.com/) distribution model.

After acquiring a (free) license, one gets the option to use a provided script to deploy Writebook as a Docker image, but also the possibility to download an archive of its source code.

I do not write books, so Writebook isn't a product that I would use personally, but a few of its characteristics combined got me interested in having a look at it:

- it's free, so all it costs me to play with it is my own time (which I'll file under "self-learning")
- it's a production-ready Rails app, which makes it a more fitted candidate to experiment with than your basic "Hello World"
- it ships with a non-extracted, non-open-source-yet, version of the House(MD) Markdown rich-text editor, which I'm really interested in learning more about

[Kamal](https://kamal-deploy.org/) is an open-source deploy tool developed by 37signals in their process of leaving the cloud. It recently received a version 2, announced at [RailsWorld 2024](https://rubyonrails.org/world/2024), and is another tool I'm excited to learn more about.

In this blog post, I'll describe the process I went through to try and deploy Writebook on Hetzner Cloud using Kamal.

## Preamble

A few things before getting started:

- Writebook is not open-source, so I will not share its source code. I can however share the files I added and diffs of the files I changed.
- The automatic install script provided by 37signals does more than just installing and starting Writebook. Among possible other things, it uses your license key, installs a `once` command, sets up automatic updates, etc. Since we're not using it, those features will be out of scope.
- I'll go through the shortest path to deploying, potentially ignoring security best practices related to, for example, avoiding to use the `root` user on my server or setting up a firewall. If you use any of this, please do your own research and adapt the setup to your needs.

## Gathering parts

Before we can really get started, there are a few things we need to gather:

- Writebook's source code. To get that, you need to acquire a (free) license on [its website](https://once.com/writebook). Once you do, you'll receive an email containing a few paragraphs explaining how to set it up, and also a link to download a zip file of Writebook's complete source code. Download that and extract it to the location of your choice.
- A server where to host Writebook. I started playing with [Hetzner Cloud](https://www.hetzner.com/cloud/) after DHH recommended it during his keynote at RailsWorld 2024. You can use anything you want, as long as you'll be able to make it accessible from the Internet and point a domain to it. (DigitalOcean, AWS, a server under your desk, etc.)
- A domain name or subdomain which you can use to point to the application we'll deploy.

## Setting up the server

Since this part will highly depend on the server solution you've chosen, I will not go into details. Here's what you need:

- Initialize your server with a recent Ubuntu distribution. We need to be able to install Docker on it (though we won't do it ourselves).
- Add your public SSH key to the server, so you can SSH to it as root.
- The (sub)domain name you want to use needs to point to your server. In my case, I'll set A and AAAA records to point writebook.davidstosik.me to my server's IP address.

That's it for the server part!

Obviously, you can deviate from these guidelines if you know what you're doing.

## Preparing the source code

The Writebook source code archive distributed by 37signals is great: it works locally out of the box. You'd only need to run these commands to run Writebook locally and try it out. (We'll assume that you use a Ruby version manager that reads the `.ruby-version` file. If not, please adapt.)

```sh-session
unzip ~/Downloads/writebook.zip ~/src/writebook
cd ~/src/writebook
bin/setup
bin/start-app
```

That's it! You can visit [http://localhost:3000](http://localhost:3000) and get started using Writebook locally.

This is however not what this post is about, so let's get started.

### Git

For Kamal to do its job, we will need to track the application on Git.

Before we initialize a Git repository and commit the Writebook code, let's make sure we have proper `.gitignore` file.

Weirdly, Writebook's source code archive doesn't come with one, so instead, I used the default one provided by Rails ([`gitignore.tt` template on GitHub](https://raw.githubusercontent.com/rails/rails/refs/heads/main/railties/lib/rails/generators/rails/app/templates/gitignore.tt)).

Now we've got a `.gitignore` file, we can initialize the git repository and commit files while knowing we won't commit anything we shouldn't.

```sh-session
git init
git add .gitignore
git commit --message "First commit: add .gitignore"
git add .
git commit --message "Add Writebook's source code"
```

_A word of caution: do not push to a public repository on GitHub! The source code is not open-source and the license does not allow its redistribution._

#### Rails' `secret_key_base`

Writebook's source code comes without [Rails credentials](https://guides.rubyonrails.org/security.html#custom-credentials), which we need, at least to provide the Rails application with a `secret_key_base`.

The easiest way to generate the files we need is to run `bin/rails credentials:edit`.
If it opens a text editor, then just save and quit. You'll have two more files in your application:

-  `config/master.key`: the master key to decrypt encrypted credentials. This file won't be committed to Git. Do not share it!
- `config/credentials.yml.enc`: encrypted credentials file, containing `secret_key_base`.

#### Resque and Redis configuration

The Writebook source code assumes that the application in production will run alongside its Redis server, which would then be accessible on `localhost`, Resque's default. This assumptions means the app did not need to declare any settings for Resque.

When we deploy the app with Kamal however, the Redis server, the web server, and the background workers will each run in their own Docker container, so we need to set up the Rails application so it knows where to find its Redis server.

Going through [Resque](https://github.com/resque/resque) and [resque-pool](https://github.com/resque/resque-pool)'s documentation, I came up with the following changes:

```diff
diff --git a/config/initializers/resque.rb b/config/initializers/resque.rb
new file mode 100644
index 0000000..f5cd3bc
--- /dev/null
+++ b/config/initializers/resque.rb
@@ -0,0 +1 @@
+Resque.redis = ENV.fetch("REDIS_URL", "localhost:6379")
diff --git a/lib/tasks/resque.rake b/lib/tasks/resque.rake
new file mode 100644
index 0000000..3f5afda
--- /dev/null
+++ b/lib/tasks/resque.rake
@@ -0,0 +1,16 @@
+require "resque/pool/tasks"
+
+# this task will get called before resque:pool:setup
+# and preload the rails environment in the pool manager
+task "resque:setup" => :environment do
+  # generic worker setup, e.g. Hoptoad for failed jobs
+end
+
+task "resque:pool:setup" do
+  # close any sockets or files in pool manager
+  ActiveRecord::Base.connection.disconnect!
+  # and re-open them in the resque worker parent
+  Resque::Pool.after_prefork do |job|
+    ActiveRecord::Base.establish_connection
+  end
+end
```

#### Dockerfile

It's interesting how the Writebook app is designed to run, when it's started by the `once` CLI, and I think it's worth pausing for a moment to examine the source code.

1. There's a single `Dockerfile` which runs a custom `bin/boot` script at launch.
2. That `bin/boot` script looks like a stripped down [Foreman](https://github.com/ddollar/foreman) alternative: it reads the `Procfile` file and starts all processes it defines:
    1. The web server, started via [Thruster](https://github.com/basecamp/thruster), Basecamp's new HTTP/2 proxy written in Go. I think it was made mainly to be used in combination with Kamal 2 but here, it's used on its own.
    2. A Redis server! This one really surprised me for multiple reasons:
        1. I expected Writebook to rely on the Solid trifecta, in particular [Solid Queue](https://github.com/rails/solid_queue), so it could ditch Rails' need for a Redis server, but it doesn't. Maybe in a future version?
        2. Redis does not run in its own container, but instead it runs along the Rails application.
    3. A set of background workers, running via [`resque-pool`](https://github.com/resque/resque-pool).

This allows the whole Writebook application to run in a single Docker container, which makes managing its deployment and execution easier using the `once` CLI on the server.

---

When we deploy with Kamal, I'd rather follow its default pattern of running web and workers on different containers from the same image, and Redis as an _accessory_.

With all that in mind, we can adjust the `Dockerfile` file to a Kamal deploy setup. I took some inspiration from [the Dockerfile a Rails 8 application comes with by default](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/Dockerfile.tt):

- Unexpose the port 443, since [kamal-proxy](https://github.com/basecamp/kamal-proxy) will handle SSL termination.
- Replace the Dockerfile's `CMD` from `bin/boot` to `bundle exec thrust bin/rails server`. (Optionally, we can delete the `bin/boot` and `Procfile` files, since we won't need them.)
- I also noticed that a Rails 8 app's default Docker entry point comes with the `db:prepare` command, so I also copied that.
- We can also remove the redis package from the `Dockerfile`, since Redis will run in its own container.

The changes look like this:

```diff
diff --git a/Dockerfile b/Dockerfile
index d974efb..f70d925 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -38,7 +38,7 @@ FROM base
 
 # Install packages needed for deployment
 RUN apt-get update -qq && \
-    apt-get install --no-install-recommends -y curl libjemalloc2 libsqlite3-0 libvips redis && \
+    apt-get install --no-install-recommends -y curl libjemalloc2 libsqlite3-0 libvips && \
     rm -rf /var/lib/apt/lists /var/cache/apt/archives
 
 # Copy built artifacts: gems, application
@@ -61,5 +61,5 @@ ENV GIT_REVISION=$GIT_REVISION
 ENTRYPOINT ["/rails/bin/docker-entrypoint"]
 
 # Start the server by default, this can be overwritten at runtime
-EXPOSE 80 443
-CMD ["bin/boot"]
+EXPOSE 80
+CMD ["bundle", "exec", "thrust", "./bin/rails", "server"]
diff --git a/Procfile b/Procfile
deleted file mode 100644
index 20e1430..0000000
--- a/Procfile
+++ /dev/null
@@ -1,3 +0,0 @@
-web: bundle exec thrust bin/start-app
-redis: redis-server config/redis.conf
-workers: FORK_PER_JOB=false INTERVAL=0.1 bundle exec resque-pool
diff --git a/bin/boot b/bin/boot
deleted file mode 100755
index 5106115..0000000
--- a/bin/boot
+++ /dev/null
@@ -1,54 +0,0 @@
-#!/usr/bin/env ruby
-
-require "json"
-require "yaml"
-
-class ProcessMonitor
-  SIGNALS = %w[ INT TERM CLD ]
-
-  def initialize(procfile)
-    @procs = process_list(procfile)
-    handle_signals
-
-    @procs.each &:start
-    @procs.each &:wait
-  end
-
-  private
-    def process_list(procfile)
-      config = YAML.load_file(procfile)
-      config.map { |name, cmd| MonitoredProcess.new(name, cmd) }
-    end
-
-    def handle_signals
-      SIGNALS.each do |signal|
-        Signal.trap(signal) do
-          @procs.each &:terminate
-        end
-      end
-    end
-end
-
-class MonitoredProcess
-  def initialize(name, cmd)
-    @name, @cmd = name, cmd
-  end
-
-  def start
-    @pid = Process.spawn(@cmd)
-  end
-
-  def wait
-    Process.wait @pid
-  rescue Errno::ECHILD
-    nil
-  end
-
-  def terminate
-    Process.kill "TERM", @pid
-  rescue Errno::ESRCH
-    nil
-  end
-end
-
-ProcessMonitor.new("Procfile")
diff --git a/bin/docker-entrypoint b/bin/docker-entrypoint
index 7ec4917..f5f81dd 100755
--- a/bin/docker-entrypoint
+++ b/bin/docker-entrypoint
@@ -5,4 +5,9 @@ if [ -f /usr/lib/*/libjemalloc.so.2 ]; then
   export LD_PRELOAD="$(echo /usr/lib/*/libjemalloc.so.2) $LD_PRELOAD"
 fi
 
+# If running the rails server then create or migrate existing database
+if [ "${@: -2:1}" == "./bin/rails" ] && [ "${@: -1:1}" == "server" ]; then
+  ./bin/rails db:prepare
+fi
+
 exec "${@}"
```

## Setting up Kamal

Now this is getting exciting. The Rails application's source code should be ready to deploy, so we now need to describe to Kamal how to deploy it.

First, add Kamal to the project then generate its default configuration files:

```sh-session
bundle add kamal
bundle exec kamal init
```

This will add `gem "kamal"` to your Gemfile, install it and create a few files in your project:

- `config/deploy.yml`: this is Kamal's deploy configuration file, and the main file we'll be editing
- `.kamal/secrets`: Kamal's secrets are stored in this file, which acts as a `.env` file
- `.kamal/hooks`: [Kamal hooks](https://kamal-deploy.org/docs/hooks/overview/). We won't need them here.

Let's edit `config/deploy.yml` first.
I'll only leave succinct comments inline, but you can find more information about the different settings in [Kamal's official documentation](https://kamal-deploy.org/docs/installation/).

```yml
# The name of the service to deploy.
# This matters especially when we use Kamal to deploy
# multiple services to the same server.
service: writebook

# The name of the Docker image to build and deploy.
# Here, I prefixed it with my GitHub username since I'll be
# using GitHub Container Registry, but I don't know if it is necessary.
image: your_github_username/writebook

# One web server, and one job server.
# Make sure to replace 1.2.3.4 by your server's IP.
servers:
  web:
    - 1.2.3.4
  job:
    hosts:
      - 1.2.3.4
    cmd: bundle exec resque-pool
    env:
      clear:
        FORK_PER_JOB: false
        INTERVAL: 0.1

# Use Kamal-Proxy, and set up SSL via Let's Encrypt.
# Make sure to replace writebook.example.com by your (sub)domain.
proxy: 
  ssl: true
  host: writebook.example.com

# The Docker Registry where to push the image once built.
# Here I'm using GitHub Docker Registry.
registry:
  server: ghcr.io
  username: your_github_username
  password:
    - KAMAL_REGISTRY_PASSWORD

builder:
  arch: amd64

env:
  clear:
    # Note the service name is used in the URL below.
    REDIS_URL: "redis://writebook-redis:6379/1"
  secret:
    - RAILS_MASTER_KEY

volumes:
  - "writebook_storage:/rails/storage"

asset_path: /rails/public/assets

# Describe the Redis server accessory,
# which will run in its own container.
# Here too, replace 1.2.3.4 with your server's IP.
accessories:
  redis:
    image: redis:7.0
    host: 1.2.3.4
    cmd: redis-server
    directories:
      - data:/data

# These aliases are so convenient! (They're default in Rails 8.)
# Reminds me of Heroku's CLI...
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell: app exec --interactive --reuse "bash"
  logs: app logs -f
  dbc: app exec --interactive --reuse "bin/rails dbconsole"
```

Then we can get to the `.kamal/secrets` file. Here I'm using the 1Password CLI to fetch  the GitHub registry token, but you're free to adjust to your own setup. Check out the [documentation](https://kamal-deploy.org/docs/commands/secrets/).

```
SECRETS=$(kamal secrets fetch --adapter 1password --account 'my_1Password_user_id' --from 'Private/GitHub' GITHUB_REGISTRY_TOKEN)
KAMAL_REGISTRY_PASSWORD=$(kamal secrets extract GITHUB_REGISTRY_TOKEN $SECRETS)
RAILS_MASTER_KEY=$(cat config/master.key)
```

## Deploying

We're almost ready to deploy!

Before we do, make sure all the changes you made to the applications are committed to Git, as by default, Kamal will only build files you have committed to your Git repository.
Then you can run `kamal setup`. This command will install Docker on your server if necessary, then deploy the application.

Subsequent deployments can be done with `kamal deploy`.

```sh-session
git add .
git commit --message "Prepare for Kamal deploy"
kamal setup
```

The first deploy will take a few minutes, as it builds the application's Docker image.
Thanks to Docker's layer caching, future deploys should get faster.

If everything went well, you should be able to visit the (sub)domain you picked earlier and see Writebook's First Run page (`/first_run`).

<div class="flex-centered">
  {% pic_cap first_run %}
    Success! 🎉
  {% endpic_cap %}
</div>

Once you've created your account, you'll land on Writebook's home page and have access to its manual.

You can also use Kamal to:

- check your server logs with `kamal logs --roles=web,job`
- open a Rails console on the server with `kamal console`
- etc.

## Going further

### Docker warnings

You may have noticed 3 warnings raised by Docker when deploying:

```
3 warnings found (use docker --debug to expand):
- FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 5)
- FromAsCasing: 'as' and 'FROM' keywords' casing do not match (line 18)
- RedundantTargetPlatform: Setting platform to predefined $TARGETPLATFORM in FROM is redundant as this is the default behavior (line 18)
```

These are not critical, but fixing them is straightforward:

```diff
diff --git a/Dockerfile b/Dockerfile
index 6fb350e..a736146 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -2,7 +2,7 @@
 
 # Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
 ARG RUBY_VERSION=3.3.1
-FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base
+FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim AS base
 
 # Rails app lives here
 WORKDIR /rails
@@ -15,7 +15,7 @@ ENV RAILS_ENV="production" \
 
 
 # Throw-away build stage to reduce size of final image
-FROM --platform=$TARGETPLATFORM base as build
+FROM base AS build
 
 # Install packages needed to build gems
 RUN apt-get update -qq && \
```

### Switching to the _Solid_ trifecta to get rid of Redis

Among the many things announced at RailsWorld 2024, the _Solid_ trifecta ([Solid Cache](https://github.com/rails/solid_cache), [Solid Queue](https://github.com/rails/solid_queue), [Solid Cable](https://github.com/rails/solid)) is a very exciting one.

Imagine this: you can run a modern Rails web application without needing a Redis server. Coupled with SQLite, you don't need a database server either!

This would simplify our Kamal setup, as we wouldn't need to run the Redis server as an accessory anymore.

If we use each of the three gems' defaults, the setup should be very straightforward. As we're not planning to run a lof traffic against this Writebook instance, I will not dive into performance concerns.

#### Solid Queue

Solid Queue is a database-based queuing backend for Active Job, Rails' background job framework.
It can replace Resque in our setup, while still providing good performance results to small and medium-sized applications.

Following [the gem's `README`](https://github.com/rails/solid_queue?tab=readme-ov-file#installation), setting it up is effortless:

```sh-session
bundle add solid_queue
bin/rails solid_queue:install
```

This will add and install the solid_queue gem, then create required configuration files.

- `bin/jobs` will be our new way to run the background worker process.
- `config/queue.yml` and `config/recurring.yml` are Solid Queue's core configuration files. We'll keep the defaults.
- `db/queue_schema.rb` is the schema for the database used by Solid Queue.
- a couple settings were also changed in `config/environments/production.rb`

(Note that by default, Solid Queue will only be enabled in production, sticking to `:async` and `:test` adapters for development and test environments respectively.)

In addition to the above, there are a few more things we need to do:

- update our Kamal config file to run `bin/jobs` instead of starting `resque-pool`
- define a `queue` database for production

The additional changes look like this:

```diff
diff --git a/config/database.yml b/config/database.yml
index c9c3f44..23643d7 100644
--- a/config/database.yml
+++ b/config/database.yml
@@ -18,3 +18,7 @@ production:
   primary:
     <<: *default
     database: storage/db/production.sqlite3
+  queue:
+    <<: *default
+    database: storage/production_queue.sqlite3
+    migrations_paths: db/queue_migrate
diff --git a/config/deploy.yml b/config/deploy.yml
index 357feff..ccf73e5 100644
--- a/config/deploy.yml
+++ b/config/deploy.yml
@@ -13,11 +13,7 @@ servers:
   job:
     hosts:
       - 65.108.85.64
-    cmd: bundle exec resque-pool
-    env:
-      clear:
-        FORK_PER_JOB: false
-        INTERVAL: 0.1
+    cmd: bin/jobs
 
 # Use Kamal-Proxy, and set up SSL via Let's Encrypt.
 proxy:
```

Commit your changes and deploy:

```sh-session
git add .
git commit --message "Use Solid Queue to manage background jobs in production"
kamal deploy
```

Try browsing on your Writebook site, edit some pages, upload some images, then check the logs to confirm no errors are raised.

You can also check that Solid Queue jobs are being created and processed:

```sh-session
$ kamal app exec --interactive --reuse 'bin/rails runner "puts \"completed jobs: #{SolidQueue::Job.finished.count}\""'
...
complete jobs: 7
```

#### Solid Cache

The process is going to be very similar: add and install the gem, then modify/add necessary configuration.

```sh-session
bundle add solid_cache
bin/rails solid_cache:install
```

```diff
diff --git a/config/database.yml b/config/database.yml
index 23643d7..af333ba 100644
--- a/config/database.yml
+++ b/config/database.yml
@@ -18,6 +18,10 @@ production:
   primary:
     <<: *default
     database: storage/db/production.sqlite3
+  cache:
+    <<: *default
+    database: storage/production_cache.sqlite3
+    migrations_paths: db/cache_migrate
   queue:
     <<: *default
     database: storage/production_queue.sqlite3
diff --git a/config/environments/production.rb b/config/environments/production.rb
index b2c282a..8c461df 100644
--- a/config/environments/production.rb
+++ b/config/environments/production.rb
@@ -40,7 +40,6 @@ Rails.application.configure do
   # for everything.
   config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
 
-  # Cache in memory for now
   config.cache_store = :solid_cache_store
 
   # Assets are cacheable
```
Commit your changes and deploy again:

```sh-session
git add .
git commit --message "Use Solid Cache in production"
kamal deploy
```

Browse the site and check it created cache entries:

```sh-session
$ kamal app exec --interactive --reuse "bin/rails runner 'puts \"cache entries: #{SolidCache::Entry.count}\"'"
...
cache entries: 8
```

#### Solid Cable

Last one! You know the drill by now.

```sh-session
bundle add solid_cable
bin/rails solid_cable:install
```

```diff
diff --git a/config/database.yml b/config/database.yml
index af333ba..ac5baea 100644
--- a/config/database.yml
+++ b/config/database.yml
@@ -18,6 +18,10 @@ production:
   primary:
     <<: *default
     database: storage/db/production.sqlite3
+  cable:
+    <<: *default
+    database: storage/production_cable.sqlite3
+    migrations_paths: db/cable_migrate
   cache:
     <<: *default
     database: storage/production_cache.sqlite3
```

```sh-session
git add .
git commit --message "Use Solid Cable in production"
kamal deploy
```

#### Clean up

Our Writebook instance now does not depend on Resque or Redis anymore, so we're able to do some clean up!

1. Kamal finds its source of truth in the deploy configuration file. Before we remove the Redis accessory from that file, we need to detroy it on the server:
    ```sh-session
    kamal accessory remove redis
    ```
2. Now we can remove all mentions to Resque and Redis from the codebase:
    ```sh-session
    bundle remove resque-pool resque redis
    git rm lib/tasks/resque.rake config/resque-pool.yml \
           config/initializers/resque.rb config/redis.conf
    ```

Also remove the Redis accessory from the Kamal configuration:

```diff
diff --git a/config/deploy.yml b/config/deploy.yml
index 16cbc18..dc9702d 100644
--- a/config/deploy.yml
+++ b/config/deploy.yml
@@ -32,9 +32,6 @@ builder:
    arch: amd64
  
  env:
-  clear:
-    # Note the service name is used in the URL below.
-    REDIS_URL: "redis://writebook-redis:6379/1"
    secret:
      - RAILS_MASTER_KEY
  
@@ -43,16 +40,6 @@ volumes:
  
  asset_path: /rails/public/assets
  
-# Describe the Redis server accessory,
-# which will run in its own container.
-accessories:
-  redis:
-    image: redis:7.0
-    host: 65.108.85.64
-    cmd: redis-server
-    directories:
-      - data:/data
-
  # These aliases are so convenient! (They're default in Rails 8.)
  # Reminds me of Heroku's CLI...
  aliases:
```

Last deploy:

```sh-session
git add .
git commit --message "Remove Resque and Redis dependencies"
kamal deploy
```

Verify that everything is working as expected, and we're done!

## Conclusion

We started with a Rails application that was setup to run with Redis on a single Docker container.
The easy way to deploy that application was to first SSH into a server and then run the command provided by ONCE.
ONCE's CLI also provided a way to easily update the application in case a new version were to be released.

After introducing Kamal and making a few changes to the application:

- We do not rely on Redis anymore. (Less dependencies = less things that can go wrong.)
- We can easily make changes to the codebase,
- which we can easily deploy to our infrastructure without ever having to SSH to our server.
- And since we're using Kamal, we can easily host other applications (possibly other ONCE applications?) on the same server.

I hope you enjoyed spending some time with me taking a look at Writebook's architecture and deploying an app with Kamal.

What will you deploy next?

If you have questions or comments, please get in touch on Twitter/X: [@davidstosik](https://twitter.com/davidstosik).
