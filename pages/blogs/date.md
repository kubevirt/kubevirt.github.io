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
        Jump to year:
        {% assign posts = site.posts %}
        {% assign groupedByYear = posts | group_by_exp:"post","post.date | date:'%Y' " %}
        <!-- Print clickable year list -->
        {% for yearitem in groupedByYear %}
          <a href="#{{ yearitem.name }}">{{ yearitem.name }}&nbsp;</a>
        {% endfor %}
        <hr/>

        <!-- Print articles per year -->
        {% for yearitem in groupedByYear %}
          <h2><a name="{{ yearitem.name }}">{{ yearitem.name }}</a></h2>

          <ul>
          {% for item in yearitem.items %}
            <li>
              <date>{{ item.date | date:'%B %e'}}</date>
              <span><a href="{{ item.url }}">{{ item.title }}</a></span>
            </li>
          {% endfor %}
          </ul>
        {% endfor %}
    </div>
  </div>
</div>
