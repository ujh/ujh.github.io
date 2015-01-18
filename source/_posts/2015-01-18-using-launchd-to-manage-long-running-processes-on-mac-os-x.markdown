---
layout: post
title: "Using launchd to manage long running processes on Mac OS X"
date: 2015-01-18 13:23:05 +0100
comments: true
categories:
  - launchd
  - monit
  - inspeqtor
  - process monitoring
---

I recently had the need to have a long running, user defined process
on my Mac. At first I thought about using
[Monit](http://mmonit.com/monit/) or
[Inspeqtor](https://github.com/mperham/inspeqtor), but then
[Jérémy Lecour](https://jeremy.wordpress.com/)
[pointed out to me](https://twitter.com/jlecour/status/556388096246562816)
that I could just use the built in [launchd](http://launchd.info/).

Lauchd can automatically start processes on startup and it can monitor
them and restart them should they abort. Adding one yourself is rather
easy. You create a file in `~/Library/LaunchAgents` in a certain
format. Here's one of mine:

``` xml gnugo13x13.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
  <dict>
    <key>Label</key>
    <string>gnugo13x13</string>
    <key>ProgramArguments</key>
    <array>
      <string>/Users/uh/bin/cgosGnuGo13x13</string>
    </array>
    <key>KeepAlive</key>
    <true/>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/uh/Library/Logs/CGOS/gnugo13x13.stdout</string>
    <key>StandardErrorPath</key>
    <string>/Users/uh/Library/Logs/CGOS/gnugo13x13.stderr</string>
  </dict>
</plist>
```

Then you notify launchd of your new file by running `lauchnctl load
~/Library/LaunchAgents/gnugo13x13.plist` and you should see a new line
in your `system.log` (accessible through
[Console.app](http://en.wikipedia.org/wiki/Console_%28OS_X%29)). If
all goes well then that's all you will see there, but if starting the
log didn't work you will see that mentioned in the `system.log`, too.

Now let's go through the interesting parts of that file. As you may
have already guessed we essentially setup key value pairs here. An XML
element `key` defines the key name and the next element defines the
value.

`Label` is the name of your job. It needs to be unique and it
is used in the `system.log` whenever there is something happening
(stop, start, crash, ...) with your job.

`ProgramArguments` is an array of strings that make up your system
call. The first one is the path to the executable you want to run, and
the others are command line arguments. If you don't have any command
line arguments you can just use `Program`. So, I probably should have
used `Program` in my example file, but that's the actual file from my
system and it works, so why change it, right? ;)


`KeepAlive` is optional and means that launchd will restart your job
should it terminate. `RunAtLoad` is necessary to automatically start
your job when you turn on your computer.

The last two, `StandardOutPath` and `StandardErrorPath` should be self
explanatory. They are paths to files that will be used to log the
stdout and stderr of your job. There's just one thing you need to keep
in mind. The folder where these files reside needs to exist before you
start the job. It will be created by launchd for you, but it will be
owned by root and therefore the job won't be able to write in there
and the job will fail.

Detailed information on everything that you can do with launchd can be
found at [launchd.info](http://launchd.info/).
