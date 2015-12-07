---
layout: post
title: "Iomrascálaí 0.3.0 released"
date: 2015-12-07 17:29:23 +0100
comments: true
categories:
  - ai
  - artificial intelligence
  - baduk
  - go
  - iomrascálaí
  - rust
  - weiqi
---

It's been a while since I wrote about [Iomrascálaí](https://github.com/ujh/iomrascalai) the engine for the <a href="https://en.wikipedia.org/wiki/Go_(game)">game of Go</a> I'm writing in Rust. I will try to do it a bit more often from now on as I've finally found the motivation to work on it again.

So today I'd like to announce [version 0.3.0](https://github.com/ujh/iomrascalai/releases/tag/0.3.0)! It's been in the works since September and included two big improvements:

1. We're now using the RAVE heuristic in selecting which tree leaf to investigate next.
1. We use a set of 3x3 patterns to guide both the tree exploration and the move selection in the playouts.

These two changes together lead to a strength increase when playing against GnuGo of *~20% on 9x9* and *~25% on 13x13*! See the [release notes](https://github.com/ujh/iomrascalai/releases/tag/0.3.0) and the [change log](https://github.com/ujh/iomrascalai/blob/master/CHANGELOG.md) for detailed listings of what actually changed between 0.2.4 and 0.3.0.

## The plan for 0.4

The main goal for 0.4 is to finally get close to equal strength with GnuGo on 19x19. A bit task but where's the fun in picking easy tasks? ;) To achieve this goal I'm planning to work on the following issues:

1. [Speed up the playouts](https://github.com/ujh/iomrascalai/issues/201)! Just 100 playouts per second on 19x19 is really slow and it's no wonder that the engine has no chance against GnuGo.
1. [Add criticality to tree selection algorithm](https://github.com/ujh/iomrascalai/issues/210). Apparently both Pachi and CrazyStone have had success with adding this as an additional term to the formula.
1. [Tune the parameters using CLOP](https://github.com/ujh/iomrascalai/issues/200). I've moved the parameters into a config file so at least technically it's now easy to run experiments and optimize the parameters.
1. [Continue searching when the results are unclear](https://github.com/ujh/iomrascalai/issues/209). Various engines have had success with searching longer than the allocated time when the best move isn't clear (i.e. close to the second best move).
1. [Use larger patterns](https://github.com/ujh/iomrascalai/issues/231). Until now the engine only uses 3x3 patterns. It seems worthwhile to investigate if using larger patterns can help.
1. [Use a DCNN to guide the search](https://github.com/ujh/iomrascalai/issues/234). There's a pre-trained neural network that's in use by several engines to guide the search and it has improved the results significantly for them. It may be a good idea to investigate this, too.

## Challenges

1. The main challenge is computation power! Running 500 games for 9x9 and 13x13 each already takes a few days. And adding 19x19 to the mix will mean that changes will take a long time to benchmark.
1. The libraries to efficiently run the DCNN code (like Caffe of Tensorflow) have quite a lot of dependencies and it's not clear how easily they can be integrated with Rust. It will at least make compiling the bot more difficult for newcomers.

Like I said, quite a challenging plan! But I'm sure it will be a lot of fun. I will leave you with a link to talk by [Tobias Pfeiffer about computer Go](https://pragtob.wordpress.com/2015/11/21/slides-beating-go-thanks-to-the-power-of-randomness-rubyconf-2015/).
