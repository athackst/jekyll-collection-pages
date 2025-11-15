---
title: Directory
layout: page
permalink: /directory/
---

## Index of generated pages
{%- assign index_by_tag = site.data.collection_pages.articles.tags.labels %}

{% for entry in index_by_tag %}
  {% assign label = entry | first %}
  {% assign info = entry | last %}
  <h2> <a href="{{ info.index.url | relative_url }}">{{ label }}</a> ({{ info.pages.size}} )</h2>
  <p>
  {% for entry in info.pages %}
    <a href="{{ entry.url }}"> Page {{ entry.page_num }} </a>
  {% endfor %}
  </p>
{% endfor %}

## Pages by tag

{%- assign articles_by_tag = site.data.collection_pages.articles.tags %}
{%- assign index_permalink = site.data.collection_pages.articles.tags.permalink %}

{% for entry in articles_by_tag.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  {% assign tag_url = index_permalink | replace: ':field', label %}
  <h2> <a href="{{ tag_url | relative_url }}">{{ label }}</a> ({{ documents.size }})</h2>
  <ul>
  {% for entry in documents %}
    <li><a href="{{ entry.url }}">{{ entry.title }}</a></li>
  {% endfor %}
  </ul>
{% endfor %}
