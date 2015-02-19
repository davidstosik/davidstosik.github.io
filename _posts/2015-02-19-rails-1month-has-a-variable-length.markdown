---
title:  "Rails' `1.month` has a variable length in seconds"
date:   2015-02-19 19:27:20
categories: rails
---

One month ago, Ben and I investigated on [`1.day` not being an `Object`][1daynotobject]
(that's an interesting post by Ben, I suggest you read it if you want to know
what's happening under the hood).

Well I've got news for you, things only get weirder!

Let's use Timecop to freeze time first, so that we know where we're at (or should I
say *when*?).

{% highlight irb %}
irb(main):001:0> Timecop.freeze '2015/02/19'
=> 2015-02-19 00:00:00 +0900
{% endhighlight %}

Next, let's check how long a month is.
{% highlight irb %}
irb(main):002:0> 1.month
=> 2592000

irb(main):003:0> 1.month == 30*24*3600
=> true
{% endhighlight %}

So, it looks like `1.month` is 30 days, even in February, right?

*Wait, does that mean that if I add `1.month` to today (Feb. 19th, remember?), then I
won't get March 19th as one would expect?*

Let's check:
{% highlight irb %}
irb(main):004:0> Date.today + 1.month
=> 2015-03-19

irb(main):005:0> 1.month.since.to_date
=> 2015-03-19
{% endhighlight %}
Actually I do...

*But you said a month is 30 days, and I'm pretty sure that if I add 30 days to
Feb. 19th, I won't get March 19th...*

Right:
{% highlight irb %}
irb(main):006:0> Date.today + 30.days
=> 2015-03-21

irb(main):007:0> 30.days.since.to_date
=> 2015-03-21
{% endhighlight %}

*So what's up? Is `1.month` equal to 30 days, or to 28?*

The answer to that is "it depends", obviously.

[1daynotobject]: http://www.bnjs.co/2015/01/14/rails-date-class-durations-and-ruby-basicobject/

