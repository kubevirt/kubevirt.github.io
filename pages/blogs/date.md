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
        {% assign groupedByYear = site.posts | group_by_exp:"post","post.date | date:'%Y' " %}
        {% assign postsByYearMonth = site.posts | group_by_exp:"post", "post.date | date: '%B %Y'"  %}

        <!-- Print clickable year list -->
        {% for yearitem in groupedByYear %}
          <a href="#{{ yearitem.name }}">{{ yearitem.name }}&nbsp;</a>
        {% endfor %}
        <hr/>

        <!-- Print articles per year -->
        {% for yearitem in groupedByYear %}
          <h2><a name="{{ yearitem.name }}">{{ yearitem.name }}</a></h2>
          {% for yearMonth in postsByYearMonth %}
            {{ yearMonth}}
            IRANZO
            <hr>
            {% assign mymonthposts = yearMonth.items %}
            {% if mymonthposts.size > 0 %}
              {% if yearMonth.name contains yearitem.name %}
                <h3>{{ yearMonth.name | split: " "|first }}</h3>
                <ul>
                  {% for item in yearitem.items %}
                    {% assign mymonth = yearMonth.name | split: " "|first %}
                    {% if item.pub-date contains mymonth %}
                      <li>
                        <date>{{ item.date | date:'%B %e'}}</date>
                        <span><a href="{{ item.url }}">{{ item.title }}</a></span>
                      </li>
                    {% endif %}
                  {% endfor %}
                </ul>
              {% endif %}
            {% endif %}
          {% endfor %}
        {% endfor %}
    </div>
  </div>
</div>
