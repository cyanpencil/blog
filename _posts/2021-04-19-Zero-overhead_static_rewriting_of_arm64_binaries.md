---
layout: default
title:  Zero-overhead static rewriting of arm64 binaries
date:   Mon Apr 19 08:33:08 PM CEST 2021
---

Hello,

So for my master thesis I worked on a nice static rewriter for aarch64 binaries. 
It's pretty cool, and has the following features:

- "_Zero_" overhead  (less than <1% without instrumentation)
- First symbolization approach on aarch64
- Small (<3k LOC of python) and built to be easy to add instrumentation modules
- Address Sanitization implemented as intrumentation pass that lets you add 
  ASAN checks on closed-source binaries. Same memory sanitization result as
  running a binary through e.g. Valgrind but with almost an order of magnitude
  less overhead (very nice for fuzzing!)
  
Unfortunately, it also has the following non-features:

- Only works on C binaries (for now)
- No obfuscated/packed/self-modifying code (basically, only well-behaved compilers)
- No statically-linked binaries 
  
To be honest though, many static rewriters share the above limitations.

Anyway, here are the [slides](assets/retrowrite_slides.pdf) for my master presentation,
and here is the full [thesis](assets/retrowrite.pdf). 

Write me a mail or reach me out on [twitter](https://twitter.com/cyan_pencil) if you have any questions!

