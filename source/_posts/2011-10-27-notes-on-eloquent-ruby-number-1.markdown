---
layout: post
title: "Notes on Eloquent Ruby #1"
date: 2011-10-27 13:47
comments: true
categories: [ruby, book club, eloquent ruby]
---
The [Ruby Rogues](http://rubyrogues.com/) book club is currently reading
Eloquent Ruby and I thought I'd tag along and read the book, too. I'll be
posting my thoughts on the book in this post and in a few future posts.

## Chapter 3: Take Advantage of Ruby's Smart Collections

This chapter details the use of the Hash and Array classes and that
they can be used instead of specialized custom classes in most cases.
That's not really surprising and also that's not what I'm taking away
from this chapter. The good point are the last two pages where he
mentions that there are cases where you shouldn't use Array or Hash but
rather use specialized collections when they make sense.

His example is the following: Imagine that we want to know if a word
appears in a document. We could either use a Hash for this
``` ruby
word_is_there = {}
words.each {|word| word_is_there[word] = true }
```
or an Array
``` ruby
unique = []
words.each {|word| unique << word unless unique.include?(word)}
```
However both approaches aren't ideal because in the case of the Hash we
aren't interested in the values we store and in the case of the Array we
need to make sure the Array contains no duplicates. It turns out that in
this case we should use the Ruby Set class because it's just made for
this:

```
require 'set'

word_set = Set.new(words)
```

## Other collections from the standard library

This got me thinking and I went through the standard library to look for
other collections that you make overlook:

### Struct

Many times we use Hashes to store data like this:

``` ruby
data = {first_name: "Jon", last_name: "Snow"}
```

If we need to pass that data around a lot it might be cleaner to create
a dedicated class for it. However if it's just a container for the data
and doesn't have any other functionality we could also use a struct.
This way we get a more expressive name:

```
Struct.new("Name", :first_name, :last_name)
Struct::Name.new("Jon", "Snow")
```

### Matrix and Vector

Matrices and Vectors could be represented by Arrays but there's really
no point in not using the Matrix and Vector classes provided by the matrix
standard library.

### Anything else?

A quick look through the standard library didn't reveal any other
collections. At least I didn't see any, but I'd be happy to be proven
wrong.
