---
title:  "Using a sprite sheet on Pebble SDK"
categories: pebble
permalink: /:categories/:year/:month/:day/:title/
---

This story will probably sound dumb to people who are used to coding on Pebble, or other similar environments, but I'm sure it can help other people (and the bonus at the end might please much many people!).
I figured this out after talking with [@pedrolane][pebbleforumspedrolane], who hinted that if my images are far from 32px wide, then a sprite sheet could be a good idea. Thanks for tutoring me!

So I've been working on a watch face recently ([Pebblot][pebbleforumspebblot]), and it turns out I need a lot of image resources (each digit being different, I'll need 29 digits to display any time in 24-hour format, plus many other small bitmaps).
As it's my first work on Pebble, I went the straightest way: have each image declared as a resource in appinfo.json, then write helper functions that will load and unload the bitmaps from the resources.
At some point, thinking it might be better not to load resources too often (apparently, it uses CPU, thus battery), I tried to cache each of them in a static variable, to retrieve it next time I need to display it.
Turns out it uses a lot of memory in the heap!

## Maths.

A thing to know about bitmaps in Pebble's SDK, is that their rows must be a multiple of 32 pixels (4 bytes) long.
If not, then useless padding is added to get the required size. This padding is irrelevant data for your application, but it takes up memory!
Let's do some maths.

A [`GBitmap`][pebblesdkgbitmap] is composed of:

 - some private attributes I don't know the size of (but it's probably always the same, and hopefully not enough to care about, so I'll ignore it, basically because I don't know)
 - a `GRect`, that's a `GPoint` and a `GSize`, which are each a couple of 2-Byte scalars (hence, 8 Bytes)
 - a pointer address (1 Byte, am I right? or is it 2?)
 - the number of bytes per row, 2 more bytes

Pretty static, not really interesting. BUT, of course the `GBitmap` also stores the pixels data somewhere. That would be `H * nb` Bytes (where H is the number of lines, and nb the number of Bytes per row).

The number of bytes per row is basically the number of "bits per row" (ie. columns), ceiled to the closest multiple of 32, the whole thing then divided by 8 (because 1 Byte = 8 bits).
We get our formula for the memory used by the actual image data: `H * ceil(W/32)*4` Bytes

So a `GBitmap` weighs `11 + H * ceil(W/32)*4` Bytes in memory.


Now I'm gonna take the example of the watch face I'm working on at the moment. I need two types of digits:

  - 16 small ones, 25x55 pixels (`11 + 55*4 = 231B`)
  - 13 big ones, 27x59 pixels (`11 + 59*4 = 247B`)

![Zero]({{ "/images/2015-02-10/zero.png" | relative_url }})

*The pink zone is the memory wasted for 32-bit padding.*

If I want to keep them all in the heap, at the same time, I'm going to use `16*231 + 13*247 = 6907` Bytes of memory!

Now let's say I take all my resources, pack them together in one big `GBitmap`. Well, first of all the 11+ Bytes that each `GBitmap` needs will be required only once. And I'm also going to gain on the useless 32-bit padding.
There are two apparently efficient ways to pack all my digits in sprite sheet(s):

  - First one would be to line them all horizontally. The big image will be 59px tall, so I'm gonna waste 4 pixels for every column of a small digit.
  - Second one, to fix that, would be to make two sprite sheets, 55 and 59px high. But I'd lose more on 32-bit padding.

In my case (and that's NOT an absolute truth), the second one has a very slighter gain. Maths (again) for the first one:

![One line]({{ "/images/2015-02-10/oneline.png" | relative_url }})

I need `16*25 + 13*27 = 751` columns. `(16*25 + 13*27)/32 = 23.46`. Too bad, looks like I'm still going to spend a lot on 32-bit padding (the closest you are to the next whole number, the better). So 24 packs of 4 Bytes per row, on 59 rows. That's 5664 Bytes to which I need to add the 11+ of a `GBitmap` structure. **5675** Bytes total.

![Not bad.](http://29.media.tumblr.com/tumblr_lltzgnHi5F1qzib3wo1_400.jpg)

And maths for the second one: `11 + 55*ceil(16*25/32)*4 + 11 + 59*ceil(13*27/32)*4 = 5478` Bytes. More than a 20% gain, awesome!

![Two lines]({{ "/images/2015-02-10/twolines.png" | relative_url }})

![Fuck yeah.](http://i3.kym-cdn.com/photos/images/newsfeed/000/120/220/85f.jpg)


## In the code

You'll have to store in your code, somehow, the position of each sprite in the sheet (origin + size: it's a GRect). Either use `#define` macros, which will be replaced during compilation, ~~and use no memory~~ (like this:

```c
#define SPRITE_POS_DIGIT0_0 GRect(0,0,27,59)
```

), or constants, but then I don't know if they use memory (8 bytes per each), or not. (Update: [hmm, not exactly how it works...][redditpebbleconstant] Obviously, whichever way you choose to store your sprite positions, it's gonna take up some memory somewhere, either the app's code size, or the heap, which has the same result, as they share 24kB.)

Once you get to that point, you'll only need to use the [`gbitmap_create_as_sub_bitmap()`][pebblesdk_gbitmap_create_as_subbitmap] function to pick sprites on your sheet:

```c
GBitmap* my_sprite = gbitmap_create_as_sub_bitmap(spritesheet, SPRITE_POS_DIGIT0_0);
```

"No deep-copying occurs", which means you're just going to use 11+ more bytes each time you need a sprite.

Pretty cool, right?

## TexturePacker

Now making and maintaining a sprite sheet is tedious, especially when you're starting to add a lot of small sprites, it gets hard to pack them the best may, and to measure all dimensions and positions.

I discovered [TexturePacker][texturepacker] tonight, and played with it a while. It looks pretty good, making a sprite sheet from images I feed it with, it can even watch folders and include all images that get in there, then exports the sprite sheet in various standard formats (such as Unity).

Obviously, making sprite sheets for Pebble is not a "big thing", and it didn't have any exporter for that, so I started to write it myself: [TexturePackerPebble][texturepackerpebble].
This exporter will export a PNG sprite sheet file, plus some .c/.h files for Pebble SDK. Just import the result in your Pebble SDK project, and call `gbitmap_create_with_sprite(SPRITE_ID_YOUR_ID);` to get a `GBitmap` sprite. (You'll get a detailed "How-to" on the project's README file.)

Now you don't have to care about the sprite sheet making process at all! How cool is that?

[pebbleforumspedrolane]: http://forums.getpebble.com/profile/6493/pedrolane
[pebbleforumspebblot]: http://forums.getpebble.com/discussion/20250/watchface-wip-my-own-attempt-at-yet-another-inkblot-watchface
[pebblesdkgbitmap]: http://developer.getpebble.com/docs/c/group___graphics_types.html#struct_g_bitmap
[redditpebbleconstant]: http://www.reddit.com/r/pebbledevelopers/comments/2uds2z/question_pebble_memory_is_it_cheaper_to_use/cob2t0K
[pebblesdk_gbitmap_create_as_subbitmap]: http://developer.getpebble.com/docs/c/group___graphics_types.html#ga5d86515990747e47a76c0a16ed6b2850
[texturepacker]: https://www.codeandweb.com/texturepacker
[texturepackerpebble]: https://github.com/davidstosik/TexturePackerPebble
