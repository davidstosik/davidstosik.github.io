# davidstosik.github.io

Yet another attempt at me keeping a blog, starting by way too much time on the setup, rather than writing...

## Setup

This site is using Jekyll, but because GitHub Pages are stuck with an old version of Jekyll, and does not allow many plugins to run, it uses GitHub Actions to build the static site.

### Default branch

GitHub user pages are build and served from the [`gh-pages`](/tree/gh-pages) branch.
The dynamic Jekyll setup lives on the [`main`](/tree/main) branch.

### GitHub Action

Jekyll [officially recommends](https://jekyllrb.com/docs/continuous-integration/github-actions) the use of the [`jekyll-action`](https://github.com/helaili/jekyll-action) GitHub Action, but I've found it a bit tricky to use, and I was not pleased by the fact that it [force-pushes an empty branch](https://github.com/helaili/jekyll-action/blob/b5cd32008825218ac11871c928227fb03aca9439/entrypoint.sh#L50-L55) to your GitHub Pages branch, every time. As a consequence:
- No history of your `gh-pages` branch (or `master`, depending on your setup) is kept, hence you get no commit history of your static releases.
- [In some configurations](https://github.com/helaili/jekyll-action#known-limitation), you need to generate a Personal Access Token (PAT). The lack of clear explanation was a bit concerning.

Instead of using `jekyll-action`, I defined my [`github-pages` workflow](/.github/workflows/github-pages.yml) using only official GitHub actions and `run` commands. Here are a few benefits:

- The setup is less opaque: I do not have to check external sources to know the commands that are executed.
- I'm not passing a Personal Access Token, ie. giving access to my GitHub repositories, to a third-party (this is particularly important when working with private repositories).
- I'm not force-pushing, so I can keep a [commit history](https://github.com/davidstosik/davidstosik.github.io/commits/github-pages) of the deployed versions of my site.
- It does not need to build a Docker image, which saves a few seconds.

## Working with this setup

Simply commit to the `main` branch the changes you want to make to the site, then push them to GitHub to trigger the GitHub Action build.
Wait a minute and you should be seeing your new content on https://davidstosik.github.io.
