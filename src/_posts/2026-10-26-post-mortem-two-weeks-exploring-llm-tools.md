---
title: 'Post-mortem: Two weeks exploring LLM tools'
date: 2026-10-26
description: ''
category: dev
tags:
  - focus
  - focus-end
  - 2026W43
---

We're Monday. I supposedly spent a week (and a half!) on exploring LLM tools. How did it go?

Well, there was some good stuff but to be honest, I achieved a lot less than I had set out to.

I did not reset my Mac mini M4 and get it fully ready with all the apps I wanted to try, including a reproducible install process.

I did not create a VM for Open Claw nor migrated my existing instance.

I did not spend a good amount of time on many of the applications I wanted to try.

I did not try out local models.

## What did I do?

However, I spent a useful amount of time with ChatGPT/Codex, I installed and tried out T3 Code, and I've been using this setup to run a few experiments and get more familiar with those tools, and how I want to work with LLMs.

### ChatGPT/Codex

I spent most of my exploration time this week in the ChatGPT/Codex applications, because it's the ecosystem I spend the most money on at the moment. (A single "ChatGPT Pro 100" subscription, US$100 / JP¥16,800 per month.)

I've really enjoyed the experience overall, and ChatGPT's remote features were solid enough that I've been able to:

- Start most of the meaty work on my Mac mini M4.
- Keep the work going even when I close my laptop.
- Resume work on a different device. For example, quickly prompt an idea from my iPhone then continue the review/polishing work from my laptop, or checking on my iPhone the progress on a task that I started from my laptop.
- Codex's "Computer use" feature even meant that it had the ability to control any app that shows on screen. It's slow, since it needs to incrementally check the screen, move the cursor, click, repeat, but it got some work done too!

The main "projects" I used as an opportunity to explore ChatGPT's features were:

- Receipt2YNAB, an iOS app that I already introduced in my previous post: [Side-tracked into building an app]. I was impressed at ChatGPT's ability to use XCode and the simulator to test the app, run the app, validate screenshots. The fact that the app compiled and ran on a one-shot prompt was really a highlight of my week!
- Making an event-based local MCP proof-of-concept to understand how it works and validate my use case. (More details coming in the future, but basically I want an app that runs background processing and will notify me regularly through a new ChatGPT chat.)
- Making something with [Scarpe], following my friend [@schwad_rb]'s [prompt] (more on that too in the future).

This was overall a good experience, and I'm confident I can use ChatGPT and Codex in a workflow I like for my future projects.

However, it's not exempt of flaws, and I've detected a few frustrations and limitations that maybe other tools could address, so I'll keep exploring alternatives, not as its own project, but as the daily tool sharpening any good software engineer has the duty to perform.

I'll write a follow up that details and illustrates the issues I currently have with the ChatGPT apps.

### T3 Code

Towards the end of the week, I installed T3Code, and used it for a couple minor tasks. I really liked the idea that it could gather several subscriptions (eg. Claude and CHatGPT) behind the same interface and that it's made with a remote work first approach in mind. I do find the interface slightly confusing at times, but it might just be me being new to it. I'll try to use it more consistently for this week's project.

### Claude

Just a quick note on Claude, since I didn't spend on it the time I'd have needed to evaluate it.

The UI around defining a "remote computer" is rather confusing, and starting work remotely felt rather obscure to me, and I'm not sure the way it works is even convenient.

In particular, it looked like starting a new project required me to SSH into my machine to create a new project directory then run `claude rc`, whereas ChatGPT can all do that from its UI. On one side, it's straightforward to start a new exploration project that runs remotely, whereas on the other, it involves several steps that'd be rather painful to do on my phone.

I'll have to try and use it more to figure it out.

## Why did it go wrong?

[Side-tracked into building an app]: {% link _posts/2026-10-20-side-tracked-into-building-an-app.md %}
[Scarpe]: https://github.com/scarpe-team/scarpe
[@schwad_rb]: https://x.com/schwad_rb
[prompt]: https://x.com/schwad_rb/status/2105417133509542222
