---
title:  "Rails' `1.month` has a variable length"
date:   2015-02-19 19:27:20
categories: rails
---

One month ago, Ben and I investigated on [`1.day` not being an `Object`][1daynotobject]
 (that's an interesting post by Ben, I suggest you read it if you want to know
what's happening under the hood).

Well I've got news for you, things only get weirder!

## Discovering the problem

Let's use Timecop to freeze time first, so that we know where we're at (or should I
say *when*?).

```irb
irb(main):001:0> Timecop.freeze '2015/02/19'
=> 2015-02-19 00:00:00 +0900
```

Next, let's check how long a month is.

```irb
irb(main):002:0> 1.month
=> 2592000

irb(main):003:0> 1.month == 30*24*3600
=> true
```

So, it looks like `1.month` is 30 days, even in February, right?

*Wait, does that mean that if I add `1.month` to today (Feb. 19th, remember?), then I
won't get March 19th as one would expect?*

Let's check:

```irb
irb(main):004:0> Date.today + 1.month
=> 2015-03-19

irb(main):005:0> 1.month.since.to_date
=> 2015-03-19
```

Actually I do...

*But you said a month is 30 days, and I'm pretty sure that if I add 30 days to
Feb. 19th, I won't get March 19th...*

Right:

```irb
irb(main):006:0> Date.today + 30.days
=> 2015-03-21

irb(main):007:0> 30.days.since.to_date
=> 2015-03-21
```

*So what's up? Is `1.month` equal to 30 days, or to 28?*

The answer to that is "it depends", obviously.

## Understanding how it's working

As we found out one month ago with Ben, [`1.day` is not an `Object`][1daynotobject].
`1.month` follows the same pattern, it is an instance of `ActiveSupport::Duration`,
which allows it to behave interestingly.

As seen in Ben's post, ActiveSupport's Date and Time calculations are defined
in a couple of files, and we'll focus here on the `Date#+` method:

> [activesupport/lib/active_support/core_ext/date/calculations.rb#L96][datecalculations+]

```ruby
def plus_with_duration(other) #:nodoc:
  if ActiveSupport::Duration === other
    other.since(self)
  else
    plus_without_duration(other)
  end
end
alias_method :plus_without_duration, :+
alias_method :+, :plus_with_duration
```

When adding something to a Date using the `+` operator, if the right operand is an
instance of `ActiveSupport::Duration`, then the calculation is delegated to the
method `ActiveSupport::Duration#since`, which itself calls `#sum`.

> [activesupport/lib/active_support/duration.rb#L90][durationsum]

```ruby
def sum(sign, time = ::Time.current) #:nodoc:
  parts.inject(time) do |t,(type,number)|
    if t.acts_like?(:time) || t.acts_like?(:date)
      if type == :seconds
        t.since(sign * number)
      else
        t.advance(type => sign * number)
      end
    else
      raise ::ArgumentError, "expected a time or date, got #{time.inspect}"
    end
  end
end
```

I don't understand why the `:seconds` case is treated separately (it looks like it
would work as well with the `else` code), but the important line is
`t.advance(type => sign * number)`. Long story short,

```ruby
time + 1.month
```

is equivalent to:

```ruby
time.advance(:months => 1)
```

Note that, at no point, the value of `1.month` was converted in days, or in seconds.
It was represented as a "quantity of 1, on the month unit", all along.
Now if we jump back to `Date#advance` definition

> [activesupport/lib/active_support/core_ext/date/calculations.rb#L110][datecalculationsadvance]

```ruby
def advance(options)
  options = options.dup
  d = self
  d = d >> options.delete(:years) * 12 if options[:years]
  d = d >> options.delete(:months)     if options[:months]
  d = d +  options.delete(:weeks) * 7  if options[:weeks]
  d = d +  options.delete(:days)       if options[:days]
  d
end
```

Advancing a date one month will use `Date#>>` operator, which, according to the
[Ruby documentation][rubydocdate>>]:

> returns a date object pointing n months after self

There you have it! At no point, from beginning to end, was a number of days, or
seconds, involved.

## Consequences

Well, the consequences of such behavior are multiple, some come very handy, while
others can be dangerous.

First of all we can admit that it's pretty cool we don't have to worry about the
number of days in a month when adding a number of months to a date.

Problems arise when using the same expression in the same piece of code, but this
expression ends up having different logical values. Here's a real-life example from
the code I'm working on at the moment.

Let's consider a simple `Article` model, that has a `#valid_until` attribute.

```ruby
class Article < ActiveRecord::Base
  DEFAULT_VALIDITY = 1.month

  after_create :set_valid_until
  def set_valid_until
    self.update(valid_until: Time.now + DEFAULT_VALIDITY)

    # Schedule a Sidekiq worker to unpublish in one month.
    ArticleUnpublishWorker.perform_in(DEFAULT_VALIDITY, self.id)
  end

end
```

This code is not very pretty, but it'll do. When an article is created:

 - Its `valid_until` attribute is set to *one month* in the future.
 - A Sidekiq job is scheduled to unpublish the Article in *one month*.

(Did you notice how I used the same "*one month*" expression in the two statements
above? That mirrors the code using the same `1.month` expression in both places.)

One would expect the job to be triggered around the time the article becomes
invalid (ideally when now **is** `article.valid_until` or else a few milliseconds
to seconds after). That would be right only on 30-day months.

Let's say I create an Article today (Feb. 19th 2015). Its `valid_until` attribute
will be set to Mar. 19th, because as we saw above, adding `1.month` to a Date (or a
Time) will advance it exactly one month.
But the Sidekiq worker is scheduled to be run in `1.month`, which, all alone, is
always equal to 30 days!

There you have it, you thought you used `1.month` consistently and that dates would
match, but you're getting a 2-day shift between the time the article becomes
invalid, and the time it's actually unpublished.

---

**Update**: after checking Sidekiq's code, I believe this behavior is a bug,
and filed a pull request trying to solve it: [MyWorker.perform_in(1.month) does
not always schedule job in one month][sidekiqpr].

---

## Last one for the fun

Now for the fun, let's consider the two following expressions.
```ruby
Time.now + 1.month - Time.now - 30.days

Time.now - Time.now + 1.month - 30.days
```

All I did was reorder the members of a simple arithmetic operation, right? They
should have the same results.

Not in Rails!

```irb
irb(main):008:0> Time.now + 1.month - Time.now - 30.days
=> -172800.0

irb(main):009:0> Time.now - Time.now + 1.month - 30.days
=> 0.0
```
*(remember, time is still frozen using Timecop)*

Considering the explanation above, it will be easy for you to understand why...


[1daynotobject]: http://www.bnjs.co/2015/01/14/rails-date-class-durations-and-ruby-basicobject/
[datecalculations+]: https://github.com/rails/rails/blob/4-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb#L96
[durationsum]: https://github.com/rails/rails/blob/4-1-stable/activesupport/lib/active_support/duration.rb#L90
[datecalculationsadvance]: https://github.com/rails/rails/blob/4-1-stable/activesupport/lib/active_support/core_ext/date/calculations.rb#L110
[rubydocdate>>]: http://ruby-doc.org/stdlib-2.2.0/libdoc/date/rdoc/Date.html#method-i-3E-3E
[sidekiqpr]: https://github.com/mperham/sidekiq/pull/2198

