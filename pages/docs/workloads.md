---
layout: default
title: Workloads
permalink: /docs/workloads
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
          <li class="docs-navigation--item">
            <a href="{{ item.url }}" {% if page.title == item.title %} class="docs-navigation--item_link active" {% else %} class="docs-navigation--item_link" {% endif %}>
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
