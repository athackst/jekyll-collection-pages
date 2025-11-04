---
title: Document Categories
layout: page
permalink: /categories/
---

## Category listing

{%- assign info = site.data.collection_pages.articles.tags %}

{% for entry in info.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  {% assign meta = info.labels[label] %}
  <h2> <a href="{{ meta.page.url | relative_url }}">{{ label }}</a> ({{ documents.size }})</h2>
  <ul>
  {% for entry in documents %}
    <li><a href="{{ entry.url }}">{{ entry.title }}</a></li>
  {% endfor %}
  </ul>
{% endfor %}

