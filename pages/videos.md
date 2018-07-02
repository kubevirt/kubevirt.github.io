---
layout: default
title: Videos
permalink: /videos/
order: 10
---

<div class="container">
  <div class="row">
    <h1>{{ page.title }}</h1>
  </div>
  <div class="row">
    <div class="col-3">
      <ul class="video-navigation">
        {% for item in site.data.video_toc.toc %}
          <li {% if page.title == item.title %} class="video-navigation--item active" {% else %} class="video-navigation--item" {% endif %}>
            <a href="{{ item.url }}" class="video-navigation--item_link">
              {{ item.title }}
            </a>
          </li>
        {% endfor %}
      </ul>
    </div>
    <div class="videos">
      <iframe style="width: 100%; height: 100%;" src="https://www.youtube.com/embed/0dob7KsJizg" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>
    </div>
  </div>
</div>
