---
title: Static blog using Jekyll 4.1.0 with GitHub Pages and Actions
---

Now my blog setup is renewed and running, I thought I could write a bit about the setup.

# Before

When I started this blog (5 years ago, then dropped almost immediately..!), I used [GitHub Pages](https://pages.github.com/)' typical setup for _user pages_ (in opposition to _project pages_):

1. Create the [`davidstosik/davidstosik.github.io` repository](https://github.com/davidstosik/davidstosik.github.io).
2. Create a new Jekyll site with `jekyll new`.
3. Start writing.
4. Push changes to the `master` branch.
5. Let GitHub do its magic to build and publish the static site.

It's that simple, and [well documented](https://help.github.com/en/github/working-with-github-pages/about-github-pages-and-jekyll).

I won't explain Jekyll here as, if you found this page, you probably know what it is. If you don't, you can always take a look at [Jekyll's official website.](https://jekyllrb.com)

# Problem

When I picked up this decrepit project a few days ago, it wasn't too hard to get things restarted, but I was not completely happy with the setup.
It didn't take me long to realize that GitHub Pages are running an outdated version of Jekyll, [3.8.7](https://github.com/jekyll/jekyll/blob/v3.8.7/History.markdown#387--2020-05-08) which, even though it's fairly recent, has only received bug fixes in the last 2 years.

Also, GitHub Pages is not able to build sites that use [plugins](https://help.github.com/en/github/working-with-github-pages/about-github-pages-and-jekyll#plugins) it does not support.

Those limitations, joined with my tendency to over-engineer and look into unknown technologies for fun, got me started.

# Solution: enter GitHub Actions!

> [GitHub Actions](https://github.com/features/actions) makes it easy to automate all your software workflows, now with world-class CI/CD. Build, test, and deploy your code right from GitHub. Make code reviews, branch management, and issue triaging work the way you want.

Put simply, it is an automation tool that one can setup to run actions (such as building or publishing a static site) on specific triggers (such as pushing new content). That's exactly what I need.

## jekyll-action

Jekyll actually [provides and documents](https://jekyllrb.com/docs/continuous-integration/github-actions) a recommended way to use latest versions on GitHub Pages, based on GitHub Actions and the action named [jekyll-action](https://github.com/marketplace/actions/jekyll-actions).

This might work for and satisfy most people, and I'd recommend to try that first, if your goal is just to get over with it and start blogging.

However, I was once again a bit picky with the details, such as the need to generate a GitHub _Personal Access Token_, a setup that did not seem perfect with _user/organization pages_ or the time it takes to run.

## Custom GitHub Actions workflow

Jekyll's recommendation is to write a GitHub Actions [workflow](https://help.github.com/en/actions/configuring-and-managing-workflows) that makes use of the [`jekyll-action`](https://github.com/helaili/jekyll-action) action.

Instead, I wrote a workflow that makes only use of [GitHub official actions](https://github.com/actions/) and runs the commands necessary to build and publish the site.

You can find the GitHub Actions workflow file in my repository: [`davidstosik/davidstosik.github.io/.github/workflows/github-pages.yml`](https://github.com/davidstosik/davidstosik.github.io/blob/4404486b970c1522c76668dd27f2d4e6fdde5404/.github/workflows/github-pages.yml).

Let's go over some details.

### Branches

```yml
on:
  push:
    branches:
      - master-source
```

This part tells GitHub Actions to run the workflow when content gets pushed (or merged via a pull request) to the branch named `master-source`.

Unfortunately, [_Configuring a publishing source for your GitHub Pages site_](https://help.github.com/en/github/working-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site) only applies to _project pages_. On the other hand, _user/organization pages_ must "be built from the `master` branch".

The word "built" in the sentence above, taken from GitHub's settings pages, either means "built with GitHub Pages' Jekyll flow" or "published as static site". As we're not using GitHub Pages' Jekyll flow, the `master` branch needs to contain the static site resulting from building it with Jekyll. As a consequence, I had to choose another branch to contain the source files (Jekyll configuration, layouts, markdown content, etc), hence `master-source`.

For convenience, I configured the repository's default branch to be `master-source`.

### Double checkout

There are two important branches in this blog's repository:
- `master-source` contains the Jekyll source: configuration files, layouts, Markdown content, etc.
- `master` contains the generated static site: the HTML (and CSS, JS, etc.) files that need to be hosted and served when visiting this blog.

I found that doing a checkout operation for each branch made the process cleaner:

```yml
      - uses: actions/checkout@v2
        with:
          path: source

      - uses: actions/checkout@v2
        with:
          ref: master
          path: build
```

The resulting file structure looks like this:
```
$GITHUB_WORKSPACE
|-- source             # where `master-source` (Jekyll source) is checked out
  |-- _config.yml
  |-- index.md
  |-- README.md
  |-- _posts/
      |-- 2020-05-31-using-jekyll-410-on-github-pages-with-github-actions.md
      |-- etc...
  |-- etc...
|-- build              # where `master` (static site) is checked out and built
    |-- index.html
    |-- etc...
```

### Build environment

```yml
      - uses: actions/setup-ruby@v1
        with:
          ruby-version: '2.6'

      - name: Bundle install
        working-directory: source
        run: |
          gem install bundler --no-document
          bundle config path vendor/bundle
          bundle install --jobs 4 --retry 3
```

These actions do the following:
- install the Ruby interpreter, required to execute Jekyll
- install the Bundler gem, required to install the gems (for example Jekyll plugins) listed in `Gemfile`
- install the needed plugins and gems

### Build and publish site

```yml
      - name: Jekyll Build
        working-directory: source
        run: JEKYLL_ENV=production bundle exec jekyll build -d ../build

      - name: Commit and push changes to master
        working-directory: build
        run: |
          git config user.name "${GITHUB_ACTOR}"
          git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
          git add .
          git commit -m "Update GitHub pages from Jekyll build for commit ${GITHUB_SHA}"
          git push origin master
```

The first step builds the Jekyll site in the `build/` directory. Then the following step commits changes to the `master` branch and pushes them to GitHub.

Once the updated static files land on the `master` branch on GitHub, the site should be published!

# Result

This blog is now generated with the latest version of Jekyll (4.1.0), and I am able to update it as soon as a new version comes out. I can also use any Jekyll plugin or theme I like.

The blog still gets built automatically when I push new content to GitHub, and that publication process only takes a few seconds to complete.

If you're interested in seeing more details about my Jekyll + GitHub Pages + GitHub Actions set up, feel free to take a look at the GitHub repository: [github.com/davidstosik/davidstosik.github.io](https://github.com/davidstosik/davidstosik.github.io).
