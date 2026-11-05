# davidstosik.github.io

Yet another attempt at me keeping a blog, starting by way too much time on the setup, rather than writing...

## Setup

This site is built on Bridgetown using GitHub Actions.

With mise installed, run this from the repository root after cloning or pulling dependency changes:

```sh
bin/setup
```

The script runs through `mise exec` via its shebang, using the versions declared in `.ruby-version` and `.node-version`.
It installs the Ruby gems with `bundle install` and the Node dependencies with `npm ci`.

Start the local development server with:

```sh
bin/bt dev
```

## Working with this setup

Simply commit to the `main` branch the changes you want to make to the site, then push them to GitHub to trigger the GitHub Action build.
Wait a minute and you should be seeing your new content on https://davidstosik.github.io.
