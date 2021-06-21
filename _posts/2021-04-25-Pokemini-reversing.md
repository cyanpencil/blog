---
layout: default
title:  Pokemini-reversing
date:   Mon Apr 19 08:33:08 PM CEST 2021
---

# Pokemini reversing

Last weekend, we [organizers](https://ctftime.org/team/42934) ranked 7th in the
[Plaid CTF](https://ctftime.org/event/1199). This is my writeup for the `pokemini`
challenge. 

We didn't actually get the flag here, but we got very damn close and learnt so much
that I still wanted to share our experience. 

### The chall

The challenge was a ROM image for a forgotten gameboy clone called the `Pokemini`. 
Have a look at it:


<figure>
	<center>
	<img src="{{site.baseurl}}/assets/2021-04-25_867x1125.png" width="70%" alt="Good stuff"/>
	<figcaption>The pokemini in all it's glory</figcaption>
	</center>
</figure>

The cartridge was basically just a flag checker with some interesting music:

<figure>
	<center>
	<img src="{{site.baseurl}}/assets/2021-04-25_598x406_000.png" width="70%" alt="Good stuff"/>
	<figcaption>This gives me some oldschool keygen nostalgia. 10/10</figcaption>
	</center>
</figure>

Let's get to business.

### A warning

Before I go and explain the solution, I should before explain that in the case it may
look like a huge time was poured into this challenge, there's a good reason for it. 

I spent over 24 full hours (not counting sleep or eating) on this challenge, and I received
huge amount of help by my teammates here:

- gerald
- neopt
- gallileo
- Aaron
- SlidyBat

But we still did not solve it. So make of the follwing as you wish:

### Part 1: Lifting heavy weights

We were aware this was not gonna be easy. The architecture it was based on was rather esoteric,
since, according to wikipedia, has the following features:

- Came to markets in 2001. Barely ten games released in total before being abandoned.
- 8 bit, 4 MHz S1C88
- Weight: 70 incredible grams.
- Display: minuscule (96x64)
- Battery: legendary (60 hours, almost on par with e-ink)

So we had to look for the manual and constantly consult it during the whole weekend to 
look up instructions, register, and everything else. 

When I joined the discord channel created for the challenge, people already made some substantial
progress on the challenge. In particular, this guy SlidyBat had written a lifter for Binary Ninja
making it able to recognize control flow in the binary letting us draw the CFG. This proved
to be absolutely vital later on and without it we would have abandoned after a couple hours
I think. 

Here's a screen of it in action:

![]({{site.baseurl}}/assets/2021-04-25_1262x1379.png)

This is where I jump in thinking that it would be cool to spend a few hours learning about
an absolutely irrelevant forgotten architecture. Let's jump in the reversing part.

Another important part was about 

### Part 2: Head-bashing

We quickly found the function that dealt with flag checking through memory watches on 
where the flag was written.

Function `0x2c95`:

![](assets/2021-04-25_1262x1379_000.png)

This horrible mess was an absolute pain to understand. 

Desperate 





