---
layout: post
title: "Notes on Eloquent Ruby #3"
date: 2011-11-07 15:11
comments: true
categories: [book club, ruby, eloquent ruby]
---
In this post I'm focusing on chapter 13: *Get the Behavior You Need with Singleton and Class Methods*. This chapter was a nice wow moment for me, but also a bit embarrassing as this isn't really advanced Ruby knowledge but I've managed to never really learn it. So what does the chapter talk about? It talks about Ruby singleton and class methods and that they're basically the same thing under the hood!

### What?

So we all know that we can define class methods like this:

``` ruby
class DennisMoore
  def self.riding_through_the_night
    # ...
  end
end
```

And we also know that this is equivalent to the following:

``` ruby
class DennisMoore
end

def DennisMoore.riding_through_the_night
  # ...
end
```
Now let's compare this to defining a method on an object instead of a class (aka defining a singleton method):

``` ruby
obj = Object.new
def obj.bla
  # ...
end
```

Quite similar that code, isn't it? This could just be a coincidence, but of course being a nicely designed language it isn't.

### So how does it work?

Quite easily actually. As you know Ruby is an object oriented language down to it's core. So it comes naturally that classes are just objects, too. So when you are defining class methods you are actually defining singleton methods on the instance of <tt>Class</tt> that defines your class (<tt>DennisMoore</tt> in this case) which is no different from defining singleton methods on "normal" objects!

### And where are those methods stored?

Now that we know that we are just defining singleton methods the only question remaining is where these methods are stored? Remember, when we are calling a method on an object, Ruby searches for the method in the class of the object, then the super class and so on until it finds it. But of course we can't put our singleton methods into the class as we only want these methods to be defined for that single object. So we could come up with some hack that stores the methods somehow in the instance. Or, we could do the elegant thing and add a special class to each object that sits between it and the "real" class of that object. This way we can use the normal rules of inheritance for singleton methods. This is of course what Ruby does. It calls it the *singleton class* even.

### Wrapping up

So to summarize: Each Ruby object has a *singleton class* in the method lookup path between itself and its class. That's where singleton methods are defined. And class methods are just a special case of this as classes themselves are just objects (and instances of class <tt>Class</tt>).
