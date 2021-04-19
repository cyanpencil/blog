---
layout: default
title:  "Auto rotate vim colorscheme on day/night"
date:   2019-09-07 00:37:07 +0100
---

# Rotate vim colorscheme between day and night automatically

<!--<center>-->
<!--<img src="{{ site.baseurl }}/assets/images/vim_colorschemes.png" width="80%" align="middle"/>-->
<!--</center>-->

It happens quite often that I work on my laptop outside during the day. My
all-time favourite colorcheme,
[alduin](https://github.com/AlessandroYorba/Alduin), gets absolutely killed by
sunlight. For this reason, I have to sometimes switch to a light colorscheme.

<figure>
	<center>
	<img src="{{ site.baseurl }}/assets/images/vim_colorschemes.png" width="80%" alt="ouch, my eyes."/>
	<figcaption>Left for the night, right for the day.</figcaption>
	</center>
</figure>


Switching manually colorscheme gets tedious after the third time. But it turns
out that making it automatic is really simple, just add those lines to your `.vimrc`:

```vimscript
if strftime('%H') % 19 > 7
	set background=light
	colo lightning
else
	set background=dark
	colo alduin
endif
```

For now, I'm using [lightning](https://github.com/wimstefan/Lightning) as the light themed
colorscheme, but I'm not really a fan of it. If you know about one as cool as alduin, let
me know via email or Telegram. I really need it.

_Note: if you use [vim plug]() to manage your colorschemes, make sure to put
the `colorscheme` command after the call to `plug#end()`, otherwise you will
just end up with the default colorscheme._

