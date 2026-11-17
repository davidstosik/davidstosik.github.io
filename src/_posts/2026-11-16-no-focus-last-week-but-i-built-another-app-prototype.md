---
title: 'No "focus" last week, but I built another iOS app prototype (2026W46)'
date: 2026-11-16
description: "I couldn't spend serious time focused on producing something, but I had my coding agent make a basic iOS application."
category: dev
tags:
  - focus
  - 2026W46
---

After four nights at the hospital, our daughter Amélie was finally discharged on Saturday, November 7.
We're glad she's okay, though childhood asthma means that we'll have to keep an eye on it.

In week 45, I made the decision to take some time away from my focus experiment in order to take care of my family ([no focus this week]({% link _posts/2026-11-05-no-weekly-focus-this-week.md %})). I'd been sick too, and the mental and physical exhaustion kept me from getting back to work as soon as I'd hoped.

---

I haven't been completely inactive though!

My wife Yuko told me more than once that she wished to preserve the cute things our daughter says. So far she'd been typing them in a single note in the Apple Notes app, but suggested it could be fun to have a dedicated application to record those quotes, automatically attach a date to them, and, why not, either attach a photo or generate an illustration using AI.

While I'm not always a fan of using AI for creative/artistic endeavours, I've been using it deliberately to generate banners for some of my blog posts. I can also see how illustrating some child's quote or recounted dream with a cute drawing could be fun, and using AI might be acceptable if that illustration wouldn't have been made any other way.

This time I decided I'd try using [T3Code](https://t3.codes/) to prompt my way through the creation of this application.

I first approached the idea as a website, but the concept wasn't clear enough and I ended up producing a website that was difficult to understand.

I changed course and decided to prototype a minimal iOS application which would focus first on recording those precious quotes.

My Mac mini M4 was already set up for iOS development, and a single prompt produced my first working prototype. After a few more instructions, I'd managed to create a TestFlight group and invite Yuko, so I could get her to try the application and give me some feedback.

It's a fairly simple application which wouldn't take an experienced iOS developer much time to implement, but my very crude setup allowed me to develop it entirely through prompts from my phone, going through revisions as I received feedback from Yuko and brought it to my coding agent. I never had to open a code file, write a single line of code, or even tweak some settings in Xcode.

Through a few more sessions, I attempted implementing on-device image generation and realized that the quality (through Image Playground) was below our expectations. In my very first attempts, I sent a clumsily generated prompt to Image Playground, but even after implementing a scene planner (which generates the text description of a scene and style, based on a static prompt), I couldn't get Image Playground to produce cute illustrations that I'd want to see in the application.

<div role="group" aria-label="Illustrations of the quote">
<p class="flex-centered">“There was a lion in the garbage truck”</p>
<div class="flex-centered">
<figure style="margin: 0;">
  <img class="image" src="{% link images/2026-11-16/playground-no-plan.png %}" alt="A girl watches a garbage truck through a window, with a lion awkwardly holding a steering wheel behind the driver's cab." width="300" height="300" loading="lazy">
  <figcaption>Image Playground, without scene planning.</figcaption>
</figure>

<figure style="margin: 0;">
  <img class="image" src="{% link images/2026-11-16/playground-plan.png %}" alt="A cartoon lion sits in the cab of a green-and-white garbage truck, its mane extending above the roof." width="300" height="300" loading="lazy">
  <figcaption>Image Playground, with scene planning.</figcaption>
</figure>

<figure style="margin: 0;">
  <img class="image" src="{% link images/2026-11-16/gpt-plan.png %}" alt="A cheerful lion wearing a seat belt sits in a blue-and-white garbage truck on a leafy Japanese residential street." width="300" height="200" loading="lazy">
  <figcaption>GPT, with scene planning.</figcaption>
</figure>
</div>
</div>

Using a frontier model like [GPT‑Image‑2.6 Sunburst](https://openai.com/index/introducing-images-2-6/) will require more work, including, as I understand it, implementing a small back-end to route image generation to OpenAI's API without exposing an API token in the iOS app I'll distribute. Because it's work that carries more unknowns and risks, I've decided to defer it and focus first on the app's core feature and on releasing it to the App Store. This would make it the first iOS application I release publicly, so I'm very excited about that, however small and simple the app itself is.

Before we get there though, I will have to make sure I understand App Store publication guidelines, and that the application is polished and ready for prime time.

<div class="flex-centered">
  <figure style="margin: 0; width: 240px;">
    <img class="image" src="{% link images/2026-11-16/01-home-single-icon.png %}" alt="iPhone Home Screen with the Cute Notes app icon." width="300" height="652" loading="lazy" style="width: 100%; height: auto;">
  </figure>
  <figure style="margin: 0; width: 240px;">
    <img class="image" src="{% link images/2026-11-16/02-welcome-empty.png %}" alt="Cute Notes welcome screen in Japanese, before any quotes have been added." width="300" height="652" loading="lazy" style="width: 100%; height: auto;">
  </figure>
  <figure style="margin: 0; width: 240px;">
    <img class="image" src="{% link images/2026-11-16/03-add-note-empty.png %}" alt="Empty add-note screen with the Japanese keyboard open." width="300" height="652" loading="lazy" style="width: 100%; height: auto;">
  </figure>
  <figure style="margin: 0; width: 240px;">
    <img class="image" src="{% link images/2026-11-16/04-single-note.png %}" alt="Cute Notes showing Amélie’s lion quote dated November 10, 2026, with its illustration." width="300" height="652" loading="lazy" style="width: 100%; height: auto;">
  </figure>
</div>

This is not going to be my focus this week, so I will work on it only when I find some free time in between other activities, and when Yuko gives me some feedback. (More soon on this week's focus.)
