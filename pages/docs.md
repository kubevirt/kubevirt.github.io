---
layout: default
title: Docs
permalink: /docs/
order: 10
---

<div class="container">
  <div class="row">
    <h1>{{ page.title }}</h1>
  </div>
  <div class="row">
    <div class="col-3">
      <ul class="docs-navigation">
        {% for item in site.data.docs_toc.toc %}
          <li {% if page.title == item.title %} class="docs-navigation--item active" {% else %} class="docs-navigation--item" {% endif %}>
            <a href="{{ item.url }}" class="docs-navigation--item_link">
              {{ item.title }}
            </a>
          </li>
        {% endfor %}
      </ul>
    </div>
    <div class="docs">
    </div>
  </div>
</div>
