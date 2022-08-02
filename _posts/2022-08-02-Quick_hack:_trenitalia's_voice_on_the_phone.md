---
layout: default
title:  "Quick hacks: trenitalia's voice on the phone"
date:   Tue Aug  2 05:37:55 PM CEST 2022
---

Welcome, dear reader, to the new episode of: "quick hacks", where we show off
hacks you can pull off yourself in less than 24 hours.

Abandon all hope of code quality, organized results, or deep understanding of what's going on: this is
just the fastest way I found to get what I wanted. Similar in spirit to a ctf writeup, more or less.


## backstory

So it all started by taking _a lot_ of italian trains during my studies, where I did back-and-forth between
Italy and Switzerland basically every month. And when travelling with italian trains there are two things that really
cannot go unnoticed:
 - soul-crushing delays
 - the voice that crushes your soul announcing those delays. 

I'm pretty sure whoever set foot on a Trenitalia station knows perfectly what I'm talking about. For who doesn't,
here's a great example of why this automatic voice is so iconic:

<center>
<iframe width="50%"  height="300"
src="https://www.youtube.com/embed/nzzM7tO4Lqg" title="YouTube video player"
frameborder="0" allow="accelerometer; autoplay; clipboard-write;
encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>
</center>

## hooked and challenged

A few years ago I used to live in a flat nicknamed the "Cyberhaus" as me and my roommate where both into security 
and hacking and we frequently hosted our ctf team while playing during weekends. Our walls were decorated with 
e-zines such as Poc||GTFO or Paged Out (when will they release the next issue?); our laptops were full of stickers; 
and we frequently had very... interesting guests. 

Well one day one of my roommate friends calls us to show some of his last phone-hacking exploits. Apart from the usual
things like Caller ID spoofing, creating conference calls, and so on, one particular thing really impressed me. He spoke 
through the phone using _exactly_ trenitalia's voice. 

This really hit me deep: such a cool hack. I was amazed that phone-hacking (phracking) still existed and was possible. 
The fact that this guy had a very misterious vibe around him convinced me that this was a particularly elaborate hack, 
and I brushed it off as something I would need to spend months on to figure out and reproduce it.

Around one week later, I forgot about the whole thing.

## our crime is that of curiousity

Yeah, that's what they say. In this case I'm a very late criminal, as it took me 2 years to jump into the rabbit hole.
It was during a hacker camp (MCH 22), where I got hooked in playing with this beautiful machine they had:

![]({{site.baseurl}}/assets/photo_2022-08-02_18-23-47.jpg)

Long story short, by working as a voluntary for the POC (phone operation
  center) and operating this machine for a whole morning, I learnt the basics
of SIP and phone protocols; I remembered about my roommate's friend
and suddenly I got the urge to investigate if we could pull off the same trenitalia's cool phrack 
to see if we could make some prank calls using this amazing machine. 

This was perfect because I had a friend who recently started working at Trenitalia, and he would be the perfect victim.
When I talked about this with some of my friends at the camp, everyone got excited and decided to help me in this 
ordeal; significant credit goes to `@neopt`, `@goeoe`, `@null` and also to `@neon`.

However, the catch was that the camp was going to end in about 24 hours; could we pull it off? 

## VoIP any%

Let's start by first received a call on your laptop, and answering with some simple music.
We want to achieve the effect of a company business landline that gives you the dreaded waiting music
for when you are in a queue to a callcenter.

The software of choice we'll use is `yate`, aka _yet another telephony engine_. Why? well, because that's what some 
other people at the camp told us to use. 
Now `yate` is amazing software, but pretty much abandonware. While there are still stable releases, most of the 
documentation is either outdated or offline. Most tutorials and examples are hosted on expired domains, or mailing
lists not archived anywhere. 

So we had pretty much nothing except the few pieces of official documentation that were still available in 2022, and
the good old battle-tested approach of _trial-and-error until it works_ (or, as my friend @dex puts it, also known as _shotgun approach_) (a quote from Rene' Ferretti perfectly summarizes this concept in italian: _"a cazzo di cane, non ci crederesti, ma funziona sempre"_)

With that said, expect very terrible explainations about why the things we did work.  I am going to leave them as an exercise to the reader.


### yate configuration

Find and install `yate` from your distro's repositories (it's in the `community` repo on Arch linux). 

The hard part here is that yate is _very generic_, meaning that it can act both as a client (e.g. a normal phone) and 
the server (e.g., who manages and forwards calls to phones), supporting loads of different protocols and outdated mechanisms
that are very hard to google. 

Now, the camp already had a server running; we needed to 
1) setup yate in client configuration, 
2) authenticate to the server,
3) get music playing on call received

Our very deep and extensive 2 hour long research resulted in the fact that you need the following 3 files configured:

#### `/etc/yate/accfile.conf`

This file contains your credentials information to authenticate to a SIP server. Here `<username>` and `<password>` should
be given to you by whoever is managing the SIP trunk (e.g. who is giving you the number). 
While at the camp we had this for free, you can use a service such as [gotrunk](https://gotrunk.com/) that will give you 
a free trial SIP trunk account with one number for one month.

```
[linedue]
enabled=yes
protocol=sip
number=<the number you want to receive calls to>
username=<username>
authname=<username> # same as before? maybe? we're not sure why it's necessary
password=<password>
domain=eu.st.ssl7.net # URL of the sip trunk; this is gotrunk's url 
registrar=eu.st.ssl7.net # same as before? again? we're confused
interval=120
```

#### `/etc/yate/regexroute.conf`

This file comes directly from hell as it tells yate how to route calls though regexes. Luckily 
our use case is very simple, we want to route everything to music. 

There is a yate module called `moh` (music on hold); it's enabled by default, and to use it we just need
this in regexroute.conf:

```
.*=moh/myline0

;^9080$=tone/dial # test if you can receive calls on the number "9080"
                  # a beeping tone will be heard from the other side
```

Now we need to configure the actual music:


#### `/etc/yate/moh.conf`

Here you can configure a bash command that plays some music. 

```
myline0=while true; do mpg123 -q -m -r 8000 -s -Z numbers.mp3; done
```

Here's quite important that you use a tool that easily outputs raw audio to stdout. 
Yate's documentation recommends to use `madplay` but that's been discontinued ages ago.
So we use `mpg123`, with the following flags:
 - `-q`: quiet, shut up, leave my terminal alone 
 - `-m`: mix both channels and output only mono. This is necessary. There is probably a very good reason why; maybe all phone codecs only work in mono? not sure.
 - `-r 8000`: sample rate; you can change this from 8000 but it will speed up/slow down sound. Not sure why 8000 is "1.0x" speed but that's how it is.
 - `-s` : don't play though the audio device, just output raw bytes on stdout. Necessary.
 - `-Z` : loop the file. If you put a folder here it will randomly play songs from that folder.

Amazing now run yate in a terminal; then call the number you were given by the
SIP trunk and you should listen to your own music. 


## Trenitalia's voice

Now, this is the part we thought was easy; instead we spent the majority of our time here.

You see, you can find plenty of videos online where people managed to steal the TTS engine Trenitalia uses
to produce the announcements; however, they are all from about 10 years ago. 
It turns out that the software used is called Loquendo, produced by Loquendo S.p.A. somewhere before 2010. 
This company was born as an independent branch of the huge telecommunications mammoth that is Telecom Italia S.p.A; this
should be already a noticeable red flag, comparable maybe to "_we go on a first date and she forgets her shoes at home_".

Anyway, we looked for quite a few hours trying to find this program online; but
every link was dead, every torrent was not seeded, and time was running out. 

Until, at last, we found a website that offered a webapp that had exactly the
same TTS voice we needed; probably it was running Loquendo in the backend. 
Well, since we did not have much left and the webapp was working decently well, we decided to just
bypass the webapp and write our own script that would pretend to be the webapp and do queries directly
to their backend from the command line.

I cannot really link the website, as probably the owners would not be super happy about this. I will just say that "`/ttsdemo/index.php`" is part of the URL; if you're motivated enough this should be everything you need to find it back.

Writing the script took a while since they had some checksums that needed to be set correctly and I spent a couple hours reversing their minified javascript to understand how they were calculated; this is the end result script:


```python
import requests
from hashlib import md5
import urllib.parse
import os

# stolen from https://www.<CENSORED>.com/ttsdemo/index.php

voices = {
    "english": ("EID=4&LID=1&VID=3", b"413"),
    "parlatreno": ("EID=2&LID=7&VID=7", b"277")
}

vc, vid = voices["parlatreno"]


while True:
    wow = input("> ").encode("ascii")
    result = md5(vid + wow + b"1mp35883747uetivb9tb8108wfj").hexdigest()
    print("Hash: ", result)
    safe_string = urllib.parse.quote_plus(wow)
    URL="https://cache-a.<CENSORED>.com/tts/gen.php?"+vc+"&TXT="+safe_string+"&IS_UTF8=1&EXT=mp3&FNAME=&ACC=5883747&API=&SESSION=&CS="+result+"&cache_flag=3"

    print("Sending; crossing fingers... ", result)
    s = requests.Session()
    r = s.get(URL)

    with open("out", "wb") as f:
        f.write(r.content)

    print("Received!...")
    print("Converting...")
    os.system("rm out.mp3; ffmpeg -i out out.mp3 &>/dev/null; touch done")
    print("Done!")
```

Works pretty well! This script gives you an interactive prompt and on every newline will put the output audio in `out.mp3`.

Now, however, we need to fix `/etc/yate/moh.conf` to use the interactive script to have our own robotic conversation. 

Easy, right? 

### No, that was not easy at all.

At first I tried with a simple:

```
myline0=while true; do mpg123 -f 120000 -q -m -r 8000 -s out.mp3 fi; done
```
Looks simple and clean but doesn't work. For some reason, you can hear only the first syllable or so of every audio. 
I have no idea why. No clue; if you have, please reach out to me. 

I had a hunch of an intuition though: maybe whatever codec is used is cutting
off because we don't output any audio during "silent" moments (if you look
  closely, we don't have the `-Z` flag anymore for mpg123, as we are not
looping anymore; thus we have moments where nothing is forwarded to stdout).
This was based on the feeling that, like yate, whatever thing is running in the
backend is _very_ old and still assumes that metadata can be sent via the same
audio itself (remember old phracking techniques where a particular whistle
  would make the centraline believe you put a coin in the phone booth? maybe
something similar was in effect).

So the quickest way to test this was to download a _silent_ mp3 file (please notice that silent output is very different from no output) from this [github repo](https://github.com/anars/blank-audio). 
I adapted the moh.conf to always output something (`out.mp3` if available, otherwise 2 seconds of silence):

```
parlatreno=while true; do bash -c "if [[ -f done ]]; then rm done; mpg123 -f 120000 -q -m -r 8000 -s out.mp3; else  mpg123 -f 120000 -q -m -r 8000 -s 2sec.mp3; fi;" ; done
```

And guess what? it worked!

I had a very fun time calling my friend; it took him a while to recognize I was the one controlling the voice :P


## Telegram bot

I've coded up a telegram bot for whoever wants to test trenitalia's voice. Do not abuse it!

Here is the link to the [linea gialla bot](https://t.me/linea_gialla_bot) (or search for `@linea_gialla_bot` on telegram)

<br>

---

<br>

If you liked this hack, make sure to hit me up and meet me at next year's camp
(CCC 2023). Expect some even crazier phone hacking shenanigans. If you hear
some camp-wide trains announcement, you know who's behind them.

Special credit goes to the "misterious friend" of my roommate's, the one who showed me this in the first place. Thank you so much! (I still have no clue who he is)

