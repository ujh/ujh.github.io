---
layout: post
title: "Learning Rust: Tasks and Messages Part 2"
date: 2014-08-01 08:06:26 +0200
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
[part 1 of this series](/2014/07/28/learning-rust-tasks-and-messages-part-1/)
we started implementing our Pi calculation using the Monte Carlo
method. We ended with code that works, but that still doesn't return a
value after exactly 10 seconds. In this part we'll finish the implementation.

The problem with the previous implementation was that the `worker()`
function had to wait for `montecarlopi()` to return, before it could
react to the message from `main()`. The solution to this should now be
obvious: Let's put the `montecarlopi()` calculation in a separate
task. Then `worker()` can listen to messages from both `main()` and
`montecarlopi()` at the same time.

<!-- more -->

Here's the code:

``` rust tasks-and-messages-3.rs
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
    let mut timer = Timer::new().unwrap();
    loop {
        if receive_from_main.try_recv().is_ok() {
            println!("worker(): Aborting calculation due to signal from main");
            break;
        }
        let montecarlopi_result = receive_from_montecarlo.try_recv();
        if montecarlopi_result.is_ok() {
            m = m + montecarlopi_result.unwrap();
            i = i + 1;
            let sender_clone = sender.clone();
            spawn(proc() {
                montecarlopi(n, sender_clone);
            });
        }
        timer.sleep(50);
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

And here's the output from running the program. As you can see from
lines 12-15 it's now working as intended. First `main()` sends the
signal, then `worker()` reacts immediately by sending the latest result to
`main()`, and `montecarlopi()` is left to finish its calculation (but
the result is discarded).

``` plain
$ ./tasks-and-messages-3
main(): start calculation and wait 10s
montecarlopi(): Starting calculation
montecarlopi(): Calculation done
montecarlopi(): Starting calculation
montecarlopi(): Calculation done
montecarlopi(): Starting calculation
montecarlopi(): Calculation done
montecarlopi(): Starting calculation
montecarlopi(): Calculation done
montecarlopi(): Starting calculation
main(): Sending abort to worker
worker(): Aborting calculation due to signal from main
main(): pi = 3.141339
montecarlopi(): Calculation done
```

Now let's go through the code and see what we had to change to make it
work. First let's look at `montecarlopi()`:

``` rust
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
```

Now that it's in its own task it has to communicate with the
`worker()` function and send it the result of the calculation. This is
as easy as passing in a `Sender` when calling it. The only interesting
bit here is that we use `send_opt()` to send the result to the
`worker()` instead of `send()`. This is because `send()` aborts the
program when it can't send the message (i.e. the receiver is gone). We
need to handle this case as `worker()` may now return before
`montecarlopi()` is done.

So far so good. Now we need to have a look at `worker()`. It needs to
change to wire it up correctly with the new `montecarlopi()`.

``` rust
let (sender, receive_from_montecarlo) = channel();
let initial_sender = sender.clone();
spawn(proc() {
    montecarlopi(n, initial_sender);
});
let mut timer = Timer::new().unwrap();
loop {
    if receive_from_main.try_recv().is_ok() {
        println!("worker(): Aborting calculation due to signal from main");
        break;
    }
    let montecarlopi_result = receive_from_montecarlo.try_recv();
    if montecarlopi_result.is_ok() {
        m = m + montecarlopi_result.unwrap();
        i = i + 1;
        let sender_clone = sender.clone();
        spawn(proc() {
            montecarlopi(n, sender_clone);
        });
    }
    timer.sleep(50);
}
```

First we need a new channel to communicate between `worker()` and
`montecarlopi()`. Then we start the first calculation in a new task.
And after that we enter the endless loop. In it we check for both
signals from `main()` (lines 8-11) and from `montecarlopi()` (lines
12-20). If there's a message from `main()` it means we're done and we
exit the loop. If there's a message from `montecarlopi()` it means
that the calculation is done. We then update our best guess of Pi and
start another calculation.

The concept used here in `worker()` isn't that complex. What was the
most difficult for me to get right was the setup of the channel. You
can see here that we need to pass a copy of sender. This is due to the
fact that not only does `montecarlopi()`
[take ownership](http://rustbyexample.com/move.html) of the sender,
[but also `proc()`](http://doc.rust-lang.org/tutorial.html#owned-closures).
This is designed so that Rust can safely move the `proc()` and all the
data associated with it to a different task. And we of course have to
have the channel defined outside of the loop so  that all tasks send
their data back to the same task.

And this is it for this post! In the next part we'll have a look at
how we can simplify this design. I don't know about you, but it took
me quite a while to get this design right. I can't imagine using it
like this in production code.
