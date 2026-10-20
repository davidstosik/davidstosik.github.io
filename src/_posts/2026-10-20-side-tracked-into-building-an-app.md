---
title: 'Side-tracked into building an app'
date: 2026-10-20
description: >-
  I had a plan for this week, but I spent my day on something else
category: dev
tags:
  - focus
  - 2026W43
  - Receipts2YNAB
published: true
image:
  path: /images/2026-10-20/snart-receipt2ynab-banner-v8.jpg
  width: 1920
  height: 1080
  alt: Leonard Snart explaining his plan while looking toward an iPhone displaying Receipt2YNAB.
---

![{{ page.image.alt }}]({{ page.image.path }})

> There are only four rules you need to remember: make the plan, execute the plan, expect the plan to go off the rails, throw away the plan.
>
> _– Leonard Snart in The Flash, S3:E22_

I'm not throwing [the plan] away yet, but today didn't really go as I expected, for two reasons.

## 1. A new idea that I couldn't leave alone

Last night, as I was winding down in the bath, I had an idea for a small iPhone app that would be very useful to me (and maybe others), and could be a good sample application to delegate to AI coding tools, allowing me to experiment with them in the process.

For context, [YNAB] (You Need A Budget) is a budgeting application that I've been using for more than 10 years at this point. I really like it, but unfortunately, it does not offer a feature to scan my receipts. (It only received a feature to attach a receipt's photo in March of this year!)

I thought it sounded pretty easy to develop an application which would allow me to take a photo of my receipts, scan them, identify relevant fields, show a draft transaction to the user then eventually upload it to YNAB. I'm not an iOS developer, so by "easy" I mean that with the right knowledge, there doesn't seem to be any kind of major technical hurdle to making such an app. However, it would take me a huge effort to make manually.

So I went in and prompted Codex. I must have spent **10 minutes maximum on my prompt**, then I let it work.

I thought it would take it a full night to deliver a janky application; I wasn't even confident I'd get a codebase that compiles. But lo and behold! **70 minutes** later, Receipt2YNAB was running on my phone!

It took a few interruptions to install Xcode and provide a couple of passwords, but Codex, running remotely on my Mac mini M4, had managed to produce an app that not only compiles, but also works, and sent it to my phone wirelessly.

Of course, the application was not 100% perfect and had minor issues that I had to get fixed with additional instructions, but the first shot:

- connected to my YNAB account using OAuth
- fetched my account's categories
- had a working camera screen
- scanned the photo I took of a receipt
- prefilled a YNAB transaction that I was able to adjust
- sent that transaction to YNAB through its API

I was elated! The application looks decent, it works, and it solves a paper cut in my workflow.

<div class="flex-centered">
  <figure>
    <video controls muted loop playsinline preload="metadata" width="300" style="max-width: 100%; height: auto;" aria-label="A quick screen capture demoing Receipt2YNAB">
      <source src="/videos/2026-10-20/receipt2ynab.mp4" type="video/mp4">
      <a href="/videos/2026-10-20/receipt2ynab.mp4">Download the video of the Receipt2YNAB demo.</a>
    </video>
    <figcaption>It's alive!</figcaption>
  </figure>
</div>

I've seen people work with these tools for months, praising their capabilities, building stuff, but I never myself dared to take such a drastic step. I know nothing about iOS development or Swift, I didn't look at a single file produced by the agent, and I even required it to guide me through some steps of the setup process, but in less than two hours, I had a working application that solves a real-life problem.

It's about time I make this realization! And this will probably change the way I work in the future, but I'm glad this happened relatively early in my process of refocusing myself. This project will become an opportunity to try out different AI coding tools.

## 2. Shit happens

Today, my 2.5 year-old daughter was sick. As her mom works as an employee, and we couldn't find a slot at the "sick child daycare" today, I was in charge of taking care of our daughter. Take her to the doctor, play with her, feed her, get her to take a nap, etc.

As a consequence, I had almost no time in front of my computer, and was unable to progress on my plan this week to set up several AI coding tools on my Mac mini.

However! Codex was already installed on my Mac mini, and set up for remote access from my laptop, and most importantly, from my iPhone. I was able to prompt Codex during brief breaks between caregiving tasks.

I used the opportunity to refine Receipt2YNAB, iron out some of the wrinkles, try out a few additional features and improve the scanning heuristic.

## Adjust course, but keep your eyes on the target

I let myself get distracted by a new shiny idea, and spent an evening on it instead of what I had set out to do this week. This however became a great opportunity to make progress the following day, by allowing me to prompt from my phone in the small gaps between taking care of my daughter.

In doing so, I learned more about Codex, its remote capabilities and its pitfalls: exactly the kind of knowledge that I was hoping to acquire this week.

Receipt2YNAB will receive more of my attention in the future. I'm hoping to reach a level of polish that I'm happy with and then release it on the App Store. To be continued!

[the plan]: {% link _posts/2026-10-13-one-focus-a-week.md %}
[YNAB]: https://www.ynab.com/
