---
layout: default
title: Grouped by Date
permalink: /blogs/date
navbar_active: Blogs
order: 10
---

<div class="container">
  <div class="row">
    <h1 class="page-title">{{ page.navbar_active }}</h1>
  </div>
  <div class="row">
    <div class="col-sm-12 col-md-3">
      {% include sidebar-blogs.html %}
    </div>
    <div class="col-sm-12 col-md-9 blogs">
      {% assign postsByYearMonth = site.posts | group_by_exp:"post", "post.date | date: '%B %Y'"  %}
      {% for yearMonth in postsByYearMonth %}
        <h3>{{ yearMonth.name }}</h3>
          <ul>
            {% for post in yearMonth.items %}
              <li><a href="{{ post.url }}">{{ post.title }}</a></li>
            {% endfor %}
          </ul>
      {% endfor %}
    </div>
  </div>
</div>
