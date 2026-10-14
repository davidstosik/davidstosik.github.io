---
title: I 3D-printed an adapter to put my Sesame smart lock on my door
date: 2019-04-16 09:03:30 +09:00
category: dev
description: Designing and 3D-printing an adapter to fit a Sesame smart lock around a curved door handle, from Fusion 360 prototypes to the working installation.
image: "/images/2019-04-16/sesame-smart-lock.jpg"
lang: en
---

*Originally posted [on Imgur](https://imgur.com/a/6JifUNG) on April 16, 2019. This post brings the story, photos, and videos together here on the blog.*

I backed [Candy House Inc.'s Sesame Kickstarter project](https://www.kickstarter.com/projects/candyhouse/sesame-your-key-reinvented) in 2015. Unfortunately, by the time I received my pledge rewards at the beginning of 2017, I had moved, and the lock didn't fit my new door and lock.

I stored the locks until I realized Candy House was 3D-printing adapters for some of its Amazon customers. Unfortunately, they didn't want to help me: their answer was to buy their new, smaller model made for Japan. So I took the problem into my own hands. If you're interested in the lock itself, here's [Candy House's website](https://candyhouse.co/).

<div class="flex-centered">
  {% pic_cap sesame-smart-lock.jpg, Sesame smart lock with the printed adapter before installation %}
    The Sesame smart lock with its new adapter.
  {% endpic_cap %}
</div>

This is what my door handle and lock look like. There is no flat surface on which I could stick the Sesame lock.

<div class="flex-centered">
  {% pic_cap door-handle.jpg, Curved door handle surrounding the existing thumbturn %}
    No flat surface to attach the smart lock to.
  {% endpic_cap %}
</div>

## Designing the adapter

I designed the adapter in Autodesk Fusion 360. It was my first time using the software, so it took me some time, but it was fun and I learned a lot.

<div class="flex-centered">
  {% pic_cap adapter-design.jpg, Fusion 360 model of the adapter housing %}
    The final adapter design in Fusion 360.
  {% endpic_cap %}
  {% pic_cap thumbturn-design.jpg, Fusion 360 model of the thumbturn extension %}
    This part extends the rotating knob.
  {% endpic_cap %}
</div>

Rather than printing the whole design, which takes four to five hours, on every iteration, I only printed thinner parts that allowed me to confirm the dimensions and fit.

<div class="flex-centered">
  {% pic_cap test-prints.jpg, Thin test prints used to check the adapter dimensions %}
    Test prints to check dimensions without waiting for the full print.
  {% endpic_cap %}
</div>

I realized too late that changes to my design no longer allowed the knob to rotate inside the casing. However, I learned that it is fairly easy to separate layers, and I was able to make the part shorter without reprinting it.

<div class="flex-centered">
  {% pic_cap shortened-thumbturn.jpg, Thumbturn extension shortened by separating printed layers %}
    A shorter thumbturn extension, without a reprint.
  {% endpic_cap %}
</div>

## Printing the final parts

The printer is an Ultimaker 3 Extended. My employer acquired it recently and built a whole "Fab room", as a few teams are getting into hardware prototyping. I was so happy to be allowed to use it!

<div class="flex-centered">
  <figure>
    <video controls muted loop playsinline preload="metadata" width="560" style="max-width: 100%; height: auto;" aria-label="Ultimaker 3 Extended printing the first layers of the adapter">
      <source src="/images/2019-04-16/printing-first-layers.mp4" type="video/mp4">
      <a href="/images/2019-04-16/printing-first-layers.mp4">Download the video of the first layers being printed.</a>
    </video>
    <figcaption>Printing the first few layers.</figcaption>
  </figure>
</div>

Five hours later, the print was done. Actually, this was the next morning, as I left it to print overnight. I used ABS "pearl gold" filament: that's what was loaded in the printer, and I didn't want to mess with the spools and settings.

<div class="flex-centered">
  {% pic_cap finished-print.jpg, Completed pearl gold ABS adapter %}
    The finished print the next morning.
  {% endpic_cap %}
</div>

Here is the whole assembly seen from below. Three things stand out:

1. To reproduce the door handle's curve, I used paper, a marker, and a scanner.
2. The 30° overhang didn't require any supports and came out very clean.
3. The printed thumbturn part was initially too long, so I had to cut it shorter. You can see the rough edges on its left side.

<div class="flex-centered">
  {% pic_cap assembly-from-below.jpg, Adapter assembly seen from below with the thumbturn extension inside %}
    The curve, overhang, and shortened thumbturn extension.
  {% endpic_cap %}
</div>

To reproduce the door handle's curve, I:

1. Loosened a couple of screws on the handle.
2. Slid a sheet of paper behind it.
3. Traced the curve with a marker.
4. Scanned the result.
5. Inserted the image into Fusion 360.
6. Scaled it. I still have to understand how that works properly in Fusion 360!
7. Used Fusion 360's control spline tool to trace the shape.

<div class="flex-centered">
  {% pic_cap traced-door-handle.jpg, Scanned outline and measurements of the door handle %}
    The door handle's curve, traced on paper and scanned.
  {% endpic_cap %}
</div>

Unfortunately, the print wasn't perfect. I had read about warping, but this was the first time I experienced it myself. None of my prototype prints in the same material had this problem.

<div class="flex-centered">
  {% pic_cap warped-print.jpg, Warping along the bottom edge of the printed adapter %}
    My first experience with warping.
  {% endpic_cap %}
</div>

On the first layer, it's fairly visible that the print warped and almost cracked. I wonder if the bed wasn't hot enough. Next time, I'll try hairspray and a brim, and maybe adjust the bed temperature, although I expected Cura's presets to be acceptable.

<div class="flex-centered">
  {% pic_cap warped-first-layer.jpg, Underside of the adapter showing the warped first layer %}
    The warped first layer.
  {% endpic_cap %}
</div>

## Fitting it to the door

It was easy to figure out that Candy House uses 3M Command strips to stick the Sesame lock to the door. I didn't know about those before; they might be a revolution for me! These L-size refills will go on each side of my adapter to secure it to the door.

<div class="flex-centered">
  {% pic_cap command-strips.jpg, Pack of large 3M Command refill strips %}
    Command strips to secure the adapter.
  {% endpic_cap %}
</div>

Fits like a glove! The snug fit around the door handle and the resulting friction also help reduce the strain on the Command strips. Even without them, the whole assembly was able to hold onto the door and open and close the lock.

<div class="flex-centered">
  {% pic_cap installed-adapter.jpg, Sesame smart lock fitted over the door handle with the printed adapter %}
    The adapter and smart lock installed on the door.
  {% endpic_cap %}
</div>

One issue I had to deal with early in the design phase was clearance: centering the smart lock would have made it bump into the door frame when opening the door. I had to offset it a bit away from the frame. Thanks to the Sesame's design, it isn't necessary to perfectly center the motor's rotation axis on the lock's rotation axis.

<div class="flex-centered">
  {% pic_cap door-frame-clearance.jpg, Offset smart lock clearing the frame as the door opens %}
    Offsetting the smart lock gives it enough room to clear the door frame.
  {% endpic_cap %}
</div>

Final test: it works!

<div class="flex-centered">
  <figure>
    <video controls muted loop playsinline preload="metadata" width="300" style="max-width: 100%; height: auto;" aria-label="Sesame smart lock turning the door lock through the printed adapter">
      <source src="/images/2019-04-16/working-lock.mp4" type="video/mp4">
      <a href="/images/2019-04-16/working-lock.mp4">Download the video of the working lock.</a>
    </video>
    <figcaption>The final test: the lock works with the adapter.</figcaption>
  </figure>
</div>
