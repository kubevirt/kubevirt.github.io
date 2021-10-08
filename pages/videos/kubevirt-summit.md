---
layout: videos
title: Kubevirt Summit
permalink: /videos/kubevirt-summit
navbar_active: Videos
order: 10
---
<div class="row">
  {% for item in site.data.kv-summit.list %}
  <div class="col-6">
    <figure class="figure">
      <iframe style="width: 400px; height: 300px;" src="{{ item.url }}" frameborder="0" allow="autoplay; encrypted-media" title="KubeVirt Summit Playlist" allowfullscreen></iframe>
      <figcaption class="figure-caption">
      <h3>{{item.title}}</h3>
        <p>
          {{item.intro}}
        </p>
      </figcaption>
    </figure>
  </div>
  {% endfor %}
</div>


