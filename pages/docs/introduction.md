---
layout: default
title: Introduction
permalink: /docs/introduction
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
    <div class="col">
      <h2>Title of Documentation Item</h2>
      <p class="doc-intro-text">
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Maecenas lacinia lacus vitae erat tempor, non rhoncus ante placerat. Sed non nisi ex. Phasellus id sagittis diam. Praesent mauris eros, ullamcorper nec convallis id, aliquet vitae est. Nam finibus erat at quam pharetra pellentesque. Ut elementum gravida massa, nec ullamcorper felis consectetur in. Nam laoreet, turpis sed molestie lobortis, eros risus semper nisl, vestibulum finibus nunc urna at turpis. Donec sagittis ex quam, rutrum finibus mi tincidunt ac. Suspendisse sit amet sapien egestas, commodo lorem eu, auctor magna. Fusce ullamcorper quam id mauris finibus, vitae tempor mauris rutrum. Proin varius consequat nibh, nec tincidunt sapien commodo eu.
      </p>
      <p>
        <a href="#">Read More ></a>
      </p>
    </div>
  </div>
</div>
