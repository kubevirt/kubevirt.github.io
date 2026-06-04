---
layout: videos
title: Kubevirt Summit
permalink: /videos/kubevirt-summit
navbar_active: Videos
order: 10
summits:
  - year: 2025
    playlist: PLnLpXX8KHIYxSz_aIfJaTpPvPu2Tthd5e
    description: "Watch Session 1 of KubeVirt Summit 2025 above."
  - year: 2024
    playlist: PLnLpXX8KHIYy8VOalYQ7FnLTOR0eZ5KxD
    description: "Watch Session 1 of KubeVirt Summit 2024 above."
  - year: 2023
    playlist: PLnLpXX8KHIYwe_V5pCXfXVDs-lY5dX55Q
    description: "Watch Session 1, Day 1 of KubeVirt Summit 2023 above."
  - year: 2022
    playlist: PLnLpXX8KHIYw7Wi4UswyTCd1Ca7bgb-rn
    description: "Watch Session 1, Day 1 of KubeVirt Summit 2022 above."
  - year: 2021
    playlist: PLnLpXX8KHIYyQi7Phsf5-73r5fj1AOBox
    description: "Our inaugural KubeVirt Summit!<br>Watch Session 1, Day 1 of KubeVirt Summit 2021 above."
---

<div class="row">
  {% for item in page.summits %}
  <div class="col-6">
    <figure class="figure">
      <iframe style="width: 400px; height: 300px;" src="https://www.youtube-nocookie.com/embed/videoseries?list={{ item.playlist }}" frameborder="0" allow="autoplay; encrypted-media" title="KubeVirt Summit {{ item.year }}" allowfullscreen></iframe>
      <figcaption class="figure-caption">
        <h3>KubeVirt Summit {{ item.year }}</h3>
        <p>{{ item.description }}</p>
        <p>
          <a href="https://www.youtube.com/playlist?list={{ item.playlist }}">Click here for a playlist of all of our KubeVirt Summit {{ item.year }} sessions</a>.
        </p>
      </figcaption>
    </figure>
  </div>
  {% endfor %}
</div>
