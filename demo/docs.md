---
title: Docs
layout: docs
---

{% assign categories = site.docs | group_by: "category" %}

{% for category in categories %}
  <div>
    <h3><a href="/docs/category/{{ category.name | slugify }}/">{{ category.name | default: "Uncategorized" }}</a></h3>
    <ul>
      {% for doc in category.items %}
        {% if doc.url != page.url %}
          <li>
            <a href="{{ doc.url | relative_url }}">{{ doc.title }}</a>
          </li>
        {% endif %}
      {% endfor %}
    </ul>
  </div>
{% endfor %}
