---
layout: post
title: "Notes on Eloquent Ruby #2"
date: 2011-11-03 16:31
comments: true
categories: [book club, ruby, eloquent ruby]
---
In this second post we look at chapter 10: *Construct Your Classes from Short, Focused Methods*. The first thing that comes to mind is of course that methods should be short. Some years ago my rule of thumb was that a method should fit on the screen. But now that I'm using a 27'' screen that doesn't hold true anymore, of course. Also this misses the important point of the chapter and that is: use the *composed method* technique for your methods. Paraphrasing the book the method written using the composed method technique should have three characteristics:

1. They should do a single thing only
1. They should operate on a single conceptual level, i.e. they shouldn't mix high-level and low-level things
1. They need to have a descriptive names, i.e. names that describe the purpose of the method

Adhering to these rules gives you nicely structured methods that should be easily understandable and as a side benefit they are also easily testable as each method only does one small thing and therefore there's no need for extensive mocking and setting up context.
