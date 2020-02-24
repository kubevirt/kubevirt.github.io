---
layout: page
title: Gallery
permalink: /gallery/
navbar_active: Gallery
order: 10
tags: [picture gallery, photos]
---

<div class="container">
  <div class="row">
    <div class="col-sm-12 col-md-9 blogs">
      <ul class="posts">
      {% for post in site.galleries %}
        {% if post.categories contains "gallery" %}
          <li>
            <h2 class="posts-title">
                <a href="{{ post.url | prepend: site.baseurl }}">
                  {{ post.title }}
                  <div id='{{ post.url }}'></div>
                </a>
            </h2>
            <div class="posts-date">{{ post.pub-date }}, {{ post.pub-year }}</div>
                {% if post.galleria %}

                    <script src="//code.jquery.com/jquery.min.js"></script>
                    <script>
                        $.getJSON('/assets/galleria/{{ post.galleria }}', function(data) {
                            var up = document.getElementById('{{ post.url }}');
                            up.innerHTML = '<img src="' + data[0]['image'] + '"widht="100" height="100" align="right" />';
                        });
                    </script>
              {% endif %}
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
