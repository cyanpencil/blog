---
layout: default
---

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
