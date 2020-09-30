---
layout: default
title: Grouped by Date
permalink: /blogs/date
navbar_active: Blogs
order: 10
---

<div class="container-fluid">
  <div class="row">
    <h1 class="page-title pl-3">{{ page.navbar_active }}</h1>
  </div>
  <div class="row">
    <div class="col-sm-12 col-md-4 col-lg-3 col-xl-2">
      {% include sidebar-blogs.html %}
    </div>
    <div class="col-sm-12 col-md-8 col-lg-9 col-xl-10 blogs">

{% comment %} ++++++++++ We first find start and end years ++++++++++ {% endcomment %}
{% assign startYear = 2222 %}
{% assign endYear   = 1 %}

{% for post in site.posts %}
{% comment %} +++++
"| plus: 0" casts postYear to fixnum, because "post.date | date: "%Y"" is a string
and comparing "2013" with 2012 (string / number) throws an error
+++++ {% endcomment %}
{% assign postYear = post.date | date: "%Y" | plus: 0 %}

{% if postYear > endYear %}{% assign endYear = postYear %}{% endif %}
{% if postYear < startYear %}{% assign startYear = postYear %}{% endif %}
{% endfor %}

{% comment %} +++++++++++++++ build the table +++++++++++++++ {% endcomment %}

{% assign tableContent = "<tr><th></th><th>Jan</th><th>Feb</th><th>Mar</th><th>Apr</th><th>May</th><th>Jun</th><th>Jul</th><th>Aug</th><th>Sep</th><th>Oct</th><th>Nov</th><th>Dec</th></tr>" %}

{% comment %} +++++
currentPostIndex is used to loop over post in an efficient way
Knowing that posts a sorted by date, we don't need to loop over
all posts each time we want to inspect them.
Instead we only loop through posts we don't already inspect.
+++++ {% endcomment %}
{% assign currentPostIndex = 0 %}

{% comment %} +++++ site.posts array is zero numbered, so last index = size-1 +++++ {% endcomment %}
{% assign lastPostIndex = site.posts.size | minus: 1 %}

{% comment %} +++++ Looping trough years in REVERSE order +++++ {% endcomment %}
{% for year in (startYear..endYear) reversed %}

{% assign yearRow = "<tr><th>" | append: year | append: "</th>" %}

{% comment %} +++++ Trick to create an empty array +++++ {% endcomment %}
{% assign yearCellsArray = "" | split: "/" %}

{% comment %} +++++ Looping over month reversed +++++ {% endcomment %}
{% for month in (1..12) reversed %}

    {% assign postsThisYearMonth = 0 %}
    {% assign monthCell = "<td>" %}

    {% for postIndex in (currentPostIndex..lastPostIndex) %}

      {% assign p      = site.posts[postIndex] %}
      {% assign pYear  = p.date | date: "%Y" | plus: 0 %}
      {% assign pMonth = p.date | date: "%m" | plus: 0 %}

      {% if pYear == year and pMonth == month %}
        {% assign postsThisYearMonth = postsThisYearMonth | plus: 1 %}
      {% else %}
        {% comment %} +++++ Here we stop the loop +++++ {% endcomment %}
        {% assign currentPostIndex = postIndex %}
        {% break %}
      {% endif %}

    {% endfor %}

    {% if postsThisYearMonth > 0 %}
      {% assign linkTargetId = "#" | append: year | append: "-" | append: month %}
      {% assign linkStart    = "<a href='" | append: linkTargetId | append: "'>" %}
      {% assign linkEnd      = "</a>" %}
      {% assign cellContent  = linkStart | append: postsThisYearMonth | append: linkEnd %}
    {% else %}
      {% assign cellContent  = "&nbsp;" %}
    {% endif %}

    {% assign monthCell = monthCell | append: cellContent | append: "</td>" %}
    {% assign yearCellsArray = yearCellsArray | unshift: monthCell %}

{% endfor %}

{% assign yearCells = yearCellsArray | join: "" %}
{% assign yearRow = yearRow | append: yearCells | append: "</tr>" %}
{% assign tableContent = tableContent | append: yearRow %}

{% endfor %}

<h2>Post calendar</h2>
<table class="table table-striped blogcalendar">
  <tbody>
    {{ tableContent }}
  </tbody>
</table>

{% comment %} +++++ Printing posts by Year then month +++++ {% endcomment %}

{% assign currentPostIndex = 0 %}
{% assign lastPostIndex = site.posts.size | minus: 1 %}

{% for year in (startYear..endYear) reversed %}

  <h2>{{year}}</h2>
  {% assign currentYear = year %}
  {% for month in (1..12) reversed %}

    {% assign postsArray = "" | split: "/" %}

    {% comment %} +++++ Find post for this year / month +++++ {% endcomment %}
    {% for postIndex in (currentPostIndex..lastPostIndex) %}
      {% assign p      = site.posts[postIndex] %}
      {% assign pYear  = p.date | date: "%Y" | plus: 0 %}
      {% assign pMonth = p.date | date: "%m" | plus: 0 %}

      {% if pYear == year and pMonth == month %}
        {% assign postsArray = postsArray | push: p %}
      {% else %}
        {% comment %} +++++ Here we stop the loop +++++ {% endcomment %}
        {% assign currentPostIndex = postIndex %}
        {% break %}
      {% endif %}
    {% endfor %}

    {% assign postArraySize = postsArray | size %}

    {% comment %} +++++ Printing posts if we have some for this year month +++++ {% endcomment %}
    {% if postArraySize and postArraySize > 0 %}

      {% comment %} +++++ get month name from a post.date +++++ {% endcomment %}
      {% assign post = postsArray | first %}
      {% assign monthName = post.date | date: "%B" %}

      {% assign monthId = year | append: "-" | append: month %}

      <h4 id="{{ monthId }}">{{ monthName }}</h4>
      <ul style="list-style: none;">
      {% for p in postsArray %}
        <li>
          📅 {{ p.date | date: "%d" }}: <a href="{{ site.baseurl }}{{ p.url }}">{{ p.title }}</a>
        </li>
      {% endfor %}
      </ul>
    {% endif %}

{% endfor %}

{% endfor %}

    </div>

  </div>
</div>
