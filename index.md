---
layout: default
---


<div style="margin-top:20%">
<center>
Hi
<br/>
My name is cyanpencil
<br/>
Have a look at my stuff
<br/>

[<a href="{{ site.baseurl }}/posts">posts</a>]
-
[<a href="{{ site.baseurl }}/about">about</a>]
-
[<a href="{{ site.baseurl }}/contact">contact</a>]
-
[<a href="http://demostream.cyanpencil.xyz/">demostream</a>]
</center>
</div>





{% comment %}
<ul class="entries">
  {% for post in site.posts %}
  <li>
    <a href="{{ site.baseurl }}{{ post.url }}">
	{{ post.date | date: "%d %B %Y" }}
	</a>
    <!--<h1>{{ post.title }}</h1></a>-->
    <div>{{ post.content | truncatehtml: 500 | truncatewords: 8000 }}</div>
	<br>
	<br>
  </li>
  {% endfor %}
</ul>
{% endcomment %}
