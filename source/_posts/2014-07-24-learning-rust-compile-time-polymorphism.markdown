---
layout: post
title: "Learning Rust: Compile time polymorphism"
date: 2014-07-24 08:13:51 +0200
comments: true
categories:
  - rust
  - programming
  - polymorphism
  - learning rust
  - compile time polymorphism
---

Coming from Ruby, polymorphism is a big part of the language. After
all Ruby is a (mostly) object oriented language. Going to a language
like Rust which is compiled and has an emphasis on being fast, run time
polymorphism isn't that nice as it slows down the code.  This is
because there's the overhead of selecting the right implementation of
a method at runtime and also because there's no way these calls can be
inlined.

This is where compile time polymorphism comes in. Many times it is
clear at compile time which concrete type we're going to use in the
program. We could write it down explicitly, but it is nicer (and more
flexible) if the compiler can figure it out for us.

<!-- more -->

Below is a small example of how this works. `Implementer1` and
`Implementer2` are two structs that both implement the trait
`TheTrait`. The third struct, `Container`, should be setup in such a
way that it can store any struct that implements `TheTrait`.

Setting this up correctly in Rust is a tiny bit complicated. First,
you need to let Rust know that you want to use a type variable when
defining `Container`. To do this you write `Container<T>` and then use
`T` wherever you want to refer to this type in the struct definition.
You will notice that this never mentions the trait `TheTrait`. The
place where you actually restrict this variable to the trait is in the
concrete implementation of the `Container` struct. Note that the
variable I've used in the definition of `Container` (called `T`) is
different from the one I've used in the implementation (called `X`).
Normally you wouldn't do this as this makes the code much harder to
understand, but I wanted to show that this is "just" a variable.

``` rust compile-time-polymorphic-structs.rs
#[deriving(Show)]
struct Implementer1;
#[deriving(Show)]
struct Implementer2;
#[deriving(Show)]
struct Container<T> { s: T }

trait TheTrait {}

impl TheTrait for Implementer1 {}
impl TheTrait for Implementer2 {}
impl<X: TheTrait> Container<X> {}

fn main() {
    let c1 = Container { s: Implementer1 };
    let c2 = Container { s: Implementer2 };
    println!("c1 = {}", c1);
    println!("c2 = {}", c2);
}
```

To prove that I haven't told you any lies, let's compile the program
and run it. You'll clearly see that `c1` contains `Implementer1` and
`c2` contains `Implementer2`.

``` plain
$ rustc compile-time-polymorphic-struct.rs
$ ./compile-time-polymorphic-struct
c1 = Container { s: Implementer1 }
c2 = Container { s: Implementer2 }
```

Next time we'll talk about how to do actual runtime polymorphism in
Rust. After all it's not always possible to know the type at compile time!
