---
layout: post
title: "Why every agile team should include a tester"
date: 2015-07-03 07:26:31 +0200
comments: true
categories:
  - management
  - testing
  - qa
  - quality assurance
  - agile
  - scrum
  - ci
  - continuous integration
---

A
[recent post on Jim Grey's blog about his job hunt as a QA manager](http://softwaresaltmines.com/2015/06/30/endangered-species-managers-and-directors-of-quality-assurance/)
made me think about what my ideal test setup for an agile (SCRUM like)
team would be.

The thing is, having QA as a completely separate team that tests
everything once the development team has "finished" the features and
bug fixes for the next release is very much out of line with every
agile methodology. Agile processes are (to me at least) about faster
feedback and the possibility to change direction quickly. So for
example, if you were doing SCRUM with one week sprints, do a feature
freeze every month (you know, management won't let you release each
week), and only *then* start testing all the features and bug fixes
there's quite a lot of overhead. The QA process may take a while as
everything produced in a month needs to be tested, the developers have
already moved on to new features and now have to switch *back* to
fixing their old code (which is quite a mental overhead) and once
everything has been tested, fixed, and tested again it's already 2-3
weeks later.

A better approach I found is to have the testing being done right
after the feature or bug fix is finished. Assuming you have automated
tests and an automated deployment process (I'm assuming that you're
developing a web app) you can just have your continuous integration
server run the tests and once they pass deploy the latest version of
the code to your staging server and notify the tester. That way the
tester can do the checking right away and send feedback within hours
or even minutes. After such a short amount of time the developer in
charge probably still knows enough about the code so that he can
quickly fix the issues the tester found.

Obviously a final round of QA before getting a release out the door is
still necessary, but as it can be assumed that all features and bug
fixes are correctly implemented this can now be much shorter and needs
to be less thorough. That way the release can be shipping much faster,
any you know maybe you can even ship more often than once a month.
