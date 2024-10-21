---
title: Deploying Writebook with Kamal 2
date: 2024-10-19 18:13:54.170920000 +09:00
category: dev
published: false
---

[Writebook](https://once.com/writebook) is [37Signals](https://37signals.com/)' second ONCE product.

It is a free book publishing tool based on Ruby on Rails, distributed by 37Signals under their [ONCE](https://once.com/) distribution model.

After acquiring a (free) license, one gets the option to use a provided script to deploy Writebook as a Docker image, but also the possibility to download an archive of its source code.

I do not write books, so Writebook isn't a product that I would use personally, but a few of its characteristics combined got me interested in having a look at it:

- it's free, so all it costs me to play with it is my own time (which I'll file under "self-learning")
- it's a production-ready Rails app, which makes it a more fitted candidate to experiment with than your basic "Hello World"
- it ships with a non-extracted, non-open-source-yet, version of the House(MD) Markdown rich-text editor, which I'm really interested in learning more about

[Kamal](https://kamal-deploy.org/) is an open-source deploy tool developed by 37Signals on their process of leaving the cloud. It recently received a version 2, announced at [RailsWorld 2024](https://rubyonrails.org/world/2024), and is another tool I'm excited to learn more about.

In this blog post, I'll describe the process I went through to try and deploy Writebook on Hetzner Cloud using Kamal.

## Preamble

A few things before getting started:

- Writebook is not open-source, so I will not share its source code. I can however share the files I added and diffs of the files I changed.
- The automatic install script provided by 37Signals does more than just installing and starting Writebook. Among possible other things, it uses your license key, installs a `once` command, sets up automatic updates, etc. Since we're not using it, those features will be out of scope.
- I'll go through the shortest path to deploying, potentially ignoring security best practices related to, for example, avoiding to use the `root` user on my server or setting up a firewall. If you use any of this, please do your own research and adapt the setup to your needs.

## Gathering parts

Before we can really get started, there are a few things we need to gather:

- Writebook's source code. To get that, you need to acquire a (free) license on [its website](https://once.com/writebook). Once you did, you'll receive an email containing a few paragraphs explaining how to set it up, and also a link to download a zip file of Writebook's complete source code. Download that and extract it to the location of your choice.
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

The Writebook source code archive distributed by 37Signals is great: it works locally out of the box. You'd only need to run these commands to run Writebook locally and try it out. (We'll assume that you use a Ruby version manager that reads the `.ruby-version` file. If not, please adapt.)

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

Weirdly, Writebook's source code archive doesn't come with one, so instead, I used the default one provided by Rails ([`gitignore.tt`` template on GitHub](https://raw.githubusercontent.com/rails/rails/refs/heads/main/railties/lib/rails/generators/rails/app/templates/gitignore.tt)).

Now we've got a `.gitignore` file, we can initialize the git repository and commit files while knowing we won't commit anything we shouldn't.

```sh-session
git init
git add .gitignore
git commit --message "First commit: add .gitignore"
git commit -a --message "Add Writebook's source code"
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

---

It's interesting how the Writebook app is designed to run, when it's started by the `once` CLI, and I think it's worth pausing for a moment to examine the source code.

1. There's a single `Dockerfile` which runs a custom `bin/boot` script at launch.
2. That `bin/boot` script looks like a stripped down [Foreman](https://github.com/ddollar/foreman) alternative: it reads the `Procfile` file and starts all processes it defines:
  1. The web server, started via [Thruster](https://github.com/basecamp/thruster), Basecamp's new HTTP/2 proxy written in Go. I think it was made mainly to be used in combination with Kamal 2 but here, it's used on its own.
  2. A Redis server! This one really surprised me for multiple reasons:
    a. I expected Writebook to rely on the Solid trifecta, in particular [Solid Queue](https://github.com/rails/solid_queue), so it could ditch Rails' need for a Redis server, but it doesn't. Maybe in a future version?
    b. Redis does not run in its own container, but instead it runs along the Rails application.
  3. A set of background workers, running via [`resque-pool`](https://github.com/resque/resque-pool).

This allows the whole Writebook application to run in a single Docker container, which makes managing its deployment and execution easier using the `once` CLI on the server.

---

When we deploy with Kamal, I'd rather follow its default pattern of running web and workers on different containers from the same image, and Redis as an _accessory_.

With all that in mind, we can adjust the `Dockerfile` file to a Kamal deploy setup. I took some inspiration from [the Dockerfile a Rails 8 application comes with by default](https://github.com/rails/rails/blob/main/railties/lib/rails/generators/rails/app/templates/Dockerfile.tt):

- Unexpose the port 443, since [kamal-proxy](https://github.com/basecamp/kamal-proxy) will handle SSL termination.
- Replace the Dockerfile's `CMD` from `bin/boot` to `bundle exec thrust bin/rails server`. (Optionally, we can delete the `bin/boot` and `Procfile` files, as we won't need them.)
- I also noticed that a Rails 8 app's default Docker entry point comes with the `db:prepare` command, so I also copied that.

The changes look like this:

```diff
diff --git a/Dockerfile b/Dockerfile
index d974efb..6fb350e 100644
--- a/Dockerfile
+++ b/Dockerfile
@@ -61,5 +61,5 @@ ENV GIT_REVISION=$GIT_REVISION
 ENTRYPOINT ["/rails/bin/docker-entrypoint"]
 
 # Start the server by default, this can be overwritten at runtime
-EXPOSE 80 443
-CMD ["bin/boot"]
+EXPOSE 80
+CMD ["bundle", "exec", "thrust", "./bin/rails", "server"]
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

(We could also remove unnecessary packages from the Docker image, such as Redis.)

## Setting up Kamal

Now this is getting exciting. The Rails application's source code should be ready to deploy, so we now need to describe to Kamal how to deploy it.

First, add Kamal to the project then generate its default configuration files:

```sh-session
bundle add kamal
bundle exec kamal init --skip-hooks
```

This will add `gem "kamal"` to your Gemfile, install it and create a few files in your project:

- `config/deploy.yml`: this is Kamal's deploy configuration file, and the main file we'll be editing
- `.kamal/secrets`: Kamal's secrets are stored in this file, which acts as a `.env` file
- I'm not mentioning [Kamal hooks](https://kamal-deploy.org/docs/hooks/overview/) here, since we won't be needing them.

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
    # Not the service name is used in the URL below.
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

```
git commit -a "Prepare for Kamal deploy"
kamal setup
```

---

Now we're getting in the thick of it!
The distributed source code archive works well when deployed via ONCE's official Docker image, but will be missing a few things for a Kamal deploy to be successful. Let's start with that.
