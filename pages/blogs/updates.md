---
layout: default
title: Weekly Updates
permalink: /blogs/updates
navbar_active: Blogs
order: 10
---

<div class="container-fluid">
  <div class="row">
    <h1 class="page-title pl-3">{{ page.navbar_active }}</h1>
  </div>
  <div class="row">
    <div class="col-sm-12 col-md-4 col-lg-2 col-xl-2">
      {% include sidebar-blogs.html %}
    </div>
    <div class="col-sm-12 col-md-8 col-lg-9 col-xl-10 blogs">
      <ul class="posts">
      {% for post in site.posts %}
        {% if post.categories contains "updates" %}
          <li>
            <h2 class="posts-title"><a href="{{ post.url | prepend: site.baseurl }}">{{ post.title }}</a></h2>
            <div class="posts-date">{{ post.pub-date }}, {{ post.pub-year }}</div>
              {{ post.description | strip_html | truncatewords:50 }}
              {% capture readmorelink %}
                {{ post.url | prepend: site.baseurl }}
              {% endcapture %}
              {% include readmore.html href_link= readmorelink %}
          </li>
        {% endif %}
      {% endfor %}
      </ul>
    </div>
  </div>
</div>
