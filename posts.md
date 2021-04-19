---
layout: default
title: posts
permalink: /posts/
---

# Posts 

<ul>
{% for post in site.posts %}
<li><a href="{{ site.baseurl }}{{  post.url }}" title="{{ post.title }}">{{ post.title }}</a></li>
{% endfor %}       
</ul>

