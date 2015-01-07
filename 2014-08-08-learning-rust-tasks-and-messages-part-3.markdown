---
layout: post
title: "Learning Rust: Tasks and Messages Part 3"
date: 2014-08-08 08:12:28 +0200
comments: true
categories:
  - rust
  - programming
  - learning rust
  - concurrency
  - tasks
  - learning rust tasks and messages
---

*The code examples of this blog post are available in the Git
 repository
 [tasks-and-messages](http://github.com/ujh/tasks-and-messages).*

In
[part2 on this series](/2014/08/01/learning-rust-tasks-and-messages-part-2/)
we finished our implementation. But if you look back at the code you
will agree that this is not the prettiest code ever and it would be a
nightmare to maintain (if this were real production code). So now
let's start cleaning it up!

One of the ugly bits is that we're using a loop in `worker()` to
periodically check if a new message has come in. This is problematic
in serveral ways. First, we have to randomly choose a time period
after which to check for new messages. If we choose too low, we spend
too much CPU cycles just doing these checks, and if we choose too high
we don't react to messages quick enough. Second, when we check for a
new message we have to use `try_recv()` as we don't know if a new
message has arrived. This returns a `Result` which we then have to
unpack. That's all a bit complicated for a basic check.

This all goes away if we use the `select!` macro. It let's you wait
for a new message from any number of receivers. It solves the two
problems described above, because it blocks until a new message is
there (no need to loop) and when it runs the code you know that
there's a new message, so you don't need to use `try_recv()`. With
this is mind, let's see how the code looks:

``` rust tasks-and-messages-4.rs
use std::io::Timer;
use std::rand::random;

fn montecarlopi(n: uint, sender: Sender<uint>) {
    println!("montecarlopi(): Starting calculation");
    let mut m = 0u;
    for _ in range(0u, n) {
        let x = random::<f32>();
        let y = random::<f32>();
        if (x*x + y*y) < 1.0 {
            m = m + 1;
        }
    }
    println!("montecarlopi(): Calculation done");
    sender.send_opt(m);
}

fn worker(receive_from_main: Receiver<uint>, send_to_main: Sender<f32>) {
    let mut m = 0u;
    let n = 10_000_000;
    let mut i = 0;
    let (sender, receive_from_montecarlo) = channel();
    let initial_sender = sender.clone();
    spawn(proc() {
        montecarlopi(n, initial_sender);
    });
    loop {
        select! {
            _ = receive_from_main.recv() => {
                println!("worker(): Aborting calculation due to signal from main");
                break;
            },
            montecarlopi_result = receive_from_montecarlo.recv() => {
                m = m + montecarlopi_result;
                i = i + 1;
                let sender_clone = sender.clone();
                spawn(proc() {
                    montecarlopi(n, sender_clone);
                });
            }
        }
    }
    let val = 4.0 * m.to_f32().unwrap()/(n*i).to_f32().unwrap();
    send_to_main.send(val);
}

fn main() {
    let mut timer = Timer::new().unwrap();
    let (send_from_worker_to_main, receive_from_worker) = channel();
    let (send_from_main_to_worker, receive_from_main)   = channel();
    println!("main(): start calculation and wait 10s");
    spawn(proc() {
        worker(receive_from_main, send_from_worker_to_main);
    });
    timer.sleep(10_000);
    println!("main(): Sending abort to worker");
    send_from_main_to_worker.send(0);
    println!("main(): pi = {}", receive_from_worker.recv());
}
```

That's already a bit better, as we got rid of `try_recv()` and the
`if` statements, but I feel that an abstraction over the channels
would improve the readability of the code a lot.
