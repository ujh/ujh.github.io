---
layout: post
title: "Learning Rust: Tasks and messages part 1"
date: 2014-07-28 08:11:58 +0200
comments: true
categories:
  - rust
  - programming
  - learning rust
  - concurrency
  - tasks
---

In the
[previous learning rust blog post](/2014/07/24/learning-rust-compile-time-polymorphism/)
I promised to talk about runtime polymorphism next. Instead I'm
starting what is probably going to become a multi part series about
concurrency. I'm doing this as I just happen to need this stuff for
[Iomrascálaí](https://github.com/ujh/iomrascalai), my main Rust
project. Iomrascálaí is an AI for the game of Go. Go is a two player game, and
like Chess, it is played with a time limit during tournaments. So I
need a way to tell the AI to *search for the best move for the next N
seconds* and then return the result immediately.

Explaining how the AI works is out of the scope of this blog post. The
only thing you need to know here is that it essentially is an endless
loop that does some computation and improves the result the longer it
can run. Unfortunately each iteration of the loop is rather long, so
we need to make sure we can return a result **while** we're doing the
computation of that iteration. This is where concurrency comes in
handy. What if we could run the iteration in a separate Rust task?
Then we could just return the result of the previous iteration if
needed.

But enough theory, let's get going. As we can't just implement a whole
Go AI for this blog post we need to find a simpler problem that has
the property that it returns a better value the longer it runs. The
simplest I could think of is
[calculating the value of Pi using the Monte Carlo method](http://mathfaculty.fullerton.edu/mathews/n2003/montecarlopimod.html).
Here's a simple implementation of it:

``` rust tasks-and-messages-1.rs
use std::rand::random;

fn montecarlopi(n: uint) -> f32 {
    let mut m = 0u;
    for _ in range(0u, n) {
        let x = random::<f32>();
        let y = random::<f32>();
        if (x*x + y*y) < 1.0 {
            m = m + 1;
        }
    }
    4.0 * m.to_f32().unwrap()/n.to_f32().unwrap()
}

fn main() {
    println!("For       1000 random drawings pi = {}", montecarlopi(1000));
    println!("For      10000 random drawings pi = {}", montecarlopi(10000));
    println!("For     100000 random drawings pi = {}", montecarlopi(100000));
    println!("For    1000000 random drawings pi = {}", montecarlopi(1000000));
    println!("For   10000000 random drawings pi = {}", montecarlopi(10000000));
}
```

If you run this you'll see that the value of pi calculated by this
function improves with the number of random drawings:

``` plain
uh@croissant:~/Personal/rust$ ./tasks-and-messages-1
For       1000 random drawings pi = 3.132
For      10000 random drawings pi = 3.1428
For     100000 random drawings pi = 3.14416
For    1000000 random drawings pi = 3.141072
For   10000000 random drawings pi = 3.141082
```

Next, let's rewrite this program so that it runs for 10 seconds and
prints out the value of pi. To do this we'll run the simulation in
chunks of 10 million drawings (around 2.2s on my machine) in a separate
task and let the main task wait for ten seconds. Once the 10 seconds
are over we'll send a signal to the worker task and ask it to return a
result.

This is of course a bit contrived as we could just run the simulations
in sync and regularly check if 10 seconds have passed. But we're
trying to learn about task here, remember?

Creating a new task in Rust is as easy as calling `spawn(proc() { ... })` with some
code. This however only creates a new task, but there's no way to
communicate with this task. That's where channels come it. A channel
is a pair of objects. One end can send data (the sender) and the other
end (the receiver) can receive the data sent by the sender. Now let's
put it into action:

``` rust tasks-and-messages-2.rs
use std::io::Timer;
use std::rand::random;

fn montecarlopi(n: uint) -> uint {
    let mut m = 0u;
    for _ in range(0u, n) {
        let x = random::<f32>();
        let y = random::<f32>();
        if (x*x + y*y) < 1.0 {
            m = m + 1;
        }
    }
    m
}

fn worker(receiver: Receiver<uint>, sender: Sender<f32>) {
    let mut m = 0u;
    let n = 10_000_000;
    let mut i = 0;
    loop {
        if receiver.try_recv().is_ok() {
            println!("worker(): Aborting calculation due to signal from main");
            break;
        }
        println!("worker(): Starting calculation");
        m = m + montecarlopi(n);
        println!("worker(): Calculation done");
        i = i + 1;
    }
    let val = 4.0 * m.to_f32().unwrap()/(n*i).to_f32().unwrap();
    sender.send(val);
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

What we do is as follows: We open two channels. One channel is for the
`worker()` to send the value of pi to the `main()` function
(`send_from_worker_to_main` and `receive_from_worker`). And
another channel is to send a signal from `main()` to worker to tell it
to stop the calculation and return the result
(`send_from_main_to_worker` and `receive_from_main`). To send
something along a channel you just call `send(VALUE)` and to receive
something you call `recv()`. It is important to note that `recv()` is
blocking and waits for the next value to arrive. To either run a
computation or abort we need to use the non-blocking version
(`try_recv()`) in `worker()`. `try_recv()` returns a `Result` which
can either be a wrapping of a real value (in this case `is_ok()`
returns true) or and error (in which case `is_ok()` returns false).

Running this produces the following output:

``` plain
uh@croissant:~/Personal/rust$ ./tasks-and-messages-2
main(): start calculation and wait 10s
worker(): Starting calculation
worker(): Calculation done
worker(): Starting calculation
worker(): Calculation done
worker(): Starting calculation
worker(): Calculation done
worker(): Starting calculation
worker(): Calculation done
worker(): Starting calculation
main(): Sending abort to worker
worker(): Calculation done
worker(): Aborting calculation due to signal from main
main(): pi = 3.141643
```

If you look closely at the result you will notice that we haven't yet
implemented everything as described. The `worker()` only returns a
result to `main()` once it has finished the current run of
`montecarlopi()`.

This blog post has already gotten very long so we'll end it here. In
the next installment, we'll finish implementing the program and maybe
even start cleaning up the code.

CREATE GIT REPO WITH THE CODE, PUT IT ON GITHUB AND MENTION IT HERE.
