---
title: Docs
layout: docs
toc: false
order: 1
permalink: /docs/
---
{% assign docs_info = site.data.collection_pages.docs.category %}

{% for category in docs_info.pages %}
  {% assign label = category | first %}
  {% assign documents = category | last | sort: "order" %}
  {% assign info = docs_info.labels[label] %}
  <h3><a href="{{ info.index.url | relative_url }}">{{ label | default: "Uncategorized" }}</a></h3>
  <ul>
  {% for entry in documents %}
    <li><a href="{{ entry.url }}">{{ entry.title }}</a>
        {% if entry.description %}
          <p>{{ entry.description }}</p>
        {% endif %}
    </li>
  {% endfor %}
  </ul>
{% endfor %}
