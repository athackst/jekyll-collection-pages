---
title: Articles
layout: page
style: topbar
---
<h1>Articles</h1>

<div class="d-flex flex-wrap gutter-spacious">
<!-- This loops through the articles -->
{%- for post in site.articles %}
  {%- if post.feature or post == site.posts[0] %}
  {%- include post-feature-card.html %}
  {%- else %}
  {%- include post-card.html border="border-top" %}
  {%- endif %}
{% endfor %}
</div>>
