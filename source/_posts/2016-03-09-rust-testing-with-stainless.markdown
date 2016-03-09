---
layout: post
title: "Rust testing with stainless"
date: 2016-03-09 09:39:07 +0100
comments: true
categories:
  - rust
  - tdd
  - testing
  - stainless
  - programming
  - learning rust
---

A [recent discussion](https://github.com/reem/stainless/issues/48) in the issues of [stainless](https://github.com/reem/stainless) prompted me to write a small blog post that explains the basics of testing in Rust using stainless. *Note that stainless only works with the nightly Rust compiler as it requires compiler plugins.*

First of all, let's set up the project. We will build a library and write unit as well as integration tests for it (code by [xetra11](https://github.com/xetra11)). Here's the `Cargo.toml` file:

``` toml Cargo.toml
[package]
name = "renderay_rs"
version = "0.0.1"
authors = ["xetra11 <falke_88@hotmail.com>"]

[lib]
path = "src/renderay_core.rs"

[dependencies]
stainless = "*"
```

So now let's look at the main entry point of the library. The code is just for illustration purposes and we don't really care what it does. We do however care about the first three lines.

`#![feature(plugin)]` tells the Rust compiler to turn on support for compiler plugins. As stainless is a compiler plugin this is needed.

The line after that is a bit more complicated. It does the following: It first checks if we are currently compiling for testing (e.g. running `cargo test`) If that is the case then we add the line `#![plugin(stainless)]` which enables stainless. If we don't compile for testing then we do nothing, i.e. we don't enable stainless when compiling normally (e.g. when running `cargo build`) [See this blog post](http://chrismorgan.info/blog/rust-cfg_attr.html) for an in depth explanation if `cfg_attr`.

And then we define a submodule called `test`. This is where we will write our unit tests.

``` rust src/renderay_core.rs
#![feature(plugin)]
#![cfg_attr(test, plugin(stainless))]

mod test;

pub struct Canvas {
    width: usize,
    height: usize,
    array: Vec<char>
}

impl Canvas {

    pub fn new(width: usize, height: usize, array: Vec<char>) -> Canvas {
        Canvas {
            width: width,
            height: height,
            array: array,
        }
    }

    pub fn array(&self) -> &Vec<char> {
        &self.array
    }

}

pub struct CanvasRenderer<'a> {
    canvas: &'a mut Canvas
}

impl <'a>CanvasRenderer<'a> {
    pub fn new(canvas: &'a mut Canvas) -> CanvasRenderer {
        CanvasRenderer {
            canvas: canvas
        }
    }

    pub fn render_point(&mut self, fill_symbol: char, pos_x: usize, pos_y: usize) {
        let canvas = &mut self.canvas;
        let mut array_to_fill = &mut canvas.array;
        let max_width: usize = canvas.width;
        let max_height: usize = canvas.height;
        let pos_to_draw = pos_x * pos_y;

        if pos_x > max_width || pos_y > max_height {
            panic!("Coordinates are out of array bounds")
        }

        array_to_fill[pos_to_draw] = fill_symbol;

    }
}
```

Alright, so let's have a look at the unit tests. First we configure the module as a test module (doesn't need to be compiled normally). Then we add our `use` declarations for the things we want to use in our tests. Due to implementation details of stainless we need to `pub use`. And they also need to be *outside* of the `describe!` blocks.

And then we come to the actual things added by stainless. `describe!`, `before_each`, and `it`. If you know [rspec](http://rspec.info/) then this will look very familiar. `it` is used to define individual tests and `describe!` is used to group tests. And `before_each` is executed before each test in a group of tests.

*If you look closely you will notice that due to the fact that the test module is a submodule of the code that we're testing we have access to private functions and private struct fields.*

``` rust src/test.rs
#![cfg(test)]

pub use super::CanvasRenderer;
pub use super::Canvas;

describe! canvas_renderer {

    before_each {
        let mut canvas = Canvas {
            width: 10,
            height: 10,
            array: vec!['x';10*10],
        };
    }

    it "should fill given char at given coords" {
        {
            let mut renderer: CanvasRenderer = CanvasRenderer::new(&mut canvas);
            renderer.render_point('x', 3,3);
        }
        assert_eq!('x', canvas.array[3*3]);
    }
}
```

Oh, and as we're writing a library we of course should also write integration tests. These go into the `tests/` folder of the project. It looks similar to our unit tests, but a few things are different:

1. We can just use `#![plugin(stainless)]` as we will never compile this code outside of our tests.
1. We need to add the library we're building as an external crate (through `extern crate renderay_rs;`) as this is a separate executable.
1. We cannot use private functions of struct fields here. So we need to use `Canvas::new` and a getter for the array.

``` rust tests/render_point.rs
#![feature(plugin)]
#![plugin(stainless)]

extern crate renderay_rs;

pub use renderay_rs::CanvasRenderer;
pub use renderay_rs::Canvas;

describe! integration_test {

    before_each {
        let mut canvas = Canvas::new(10, 10, vec!['x';10*10]);
    }

    it "should fill given char at given coords" {
        {
            let mut renderer: CanvasRenderer = CanvasRenderer::new(&mut canvas);
            renderer.render_point('x', 3,3);
        }
        assert_eq!('x', canvas.array()[3*3]);
    }

}
```

And running the tests looks like this:

``` text
uh@macaron:~/renderay_rs$ cargo test
    Running target/debug/render_point-f60500163e82a187

running 1 test
test integration_test::should_fill_given_char_at_given_coords ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

    Running target/debug/renderay_rs-42155898cc4eb950

running 1 test
test test::canvas_renderer::should_fill_given_char_at_given_coords ... ok

test result: ok. 1 passed; 0 failed; 0 ignored; 0 measured

    Doc-tests renderay_rs

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured
```
