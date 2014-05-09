---
layout: post
title: "How to test Rust on Travis CI"
date: 2014-05-09 16:07:51 +0200
comments: true
categories: [rust, ci, travis ci, programming, continuous integration, iomrascálaí]
---

Working with Ruby on Rails in my projects I'm used to running continuous integration on [Travis CI](https://travis-ci.org/). As this is free of charge for open source projects projects I wanted to set it up for my Rust project [Iomrascálaí](https://github.com/ujh/iomrascalai), too.

At first I used the setup provided by [Rust CI](http://www.rust-ci.org/help/), but as the project page doesn't seem to be working 100% anymore and because the Debian package they provide of the rust nightly snapshot for some reason strips the Rust version number I decided to use the official nightly snapshots instead.

It was actually quite easy to do and if you want to test your Rust project on Travis CI yourself just drop that file into your project folder and adjust the last line to run your tests!

``` yaml .travis.yml
install:
  - curl -O http://static.rust-lang.org/dist/rust-nightly-x86_64-unknown-linux-gnu.tar.gz
  - tar xfz rust-nightly-x86_64-unknown-linux-gnu.tar.gz
  - (cd rust-nightly-x86_64-unknown-linux-gnu/ && sudo ./install.sh)
script:
  - rustc --version
  - make
```
