---
layout: videos
title: Talks
permalink: /videos/talks
navbar_active: Videos
order: 10
---

<div class="row">
  {% for item in site.data.videos-talks.list %}
  <div class="col-6">
    <figure class="figure">
      <iframe style="width: 400px; height: 300px;" src="https://www.youtube-nocookie.com/embed/videoseries?list=PLnLpXX8KHIYzxJzWL6Zvp9gtfi-mffHZP" frameborder="0" allow="autoplay; encrypted-media" title="KubeVirt Talks Playlist" allowfullscreen></iframe>
      <figcaption class="figure-caption">
      <h3>KubeVirt Talks and Conference Sessions</h3>
        <p>
          The KubeVirt Community gives talks at a variety of conferences and meetups throughout the year. 
        </p>
        <p>
          Watch the most recent such session above, and be sure to check out our <br><a href="https://www.youtube.com/playlist?list=PLnLpXX8KHIYzxJzWL6Zvp9gtfi-mffHZP">YouTube Talks playlist</a> to see plenty more.
        </p>
      </figcaption>
    </figure>
  </div>
  {% endfor %}
</div>

### Upcoming Events

If you want to present a KubeVirt talk, or want to see one at a conference soon and/or meet some KubeVirt folks, check out our [KubeVirt Community Events Wiki](https://github.com/kubevirt/community/wiki/Events). <br>
This is where we track open CfPs for relevant conferences and meetups, as well as our upcoming conference/meetup sessions.
