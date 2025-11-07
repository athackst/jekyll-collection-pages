---
title: Tags
layout: page
permalink: /tags/
---

{%- assign tags_info = site.data.collection_pages.articles.tags %}
{%- assign tag_permalink = site.data.collection_pages.articles.tags.permalink %}

{% include post-index.html
  collection=tags_info.pages
  collection_permalink=tag_permalink
  replace_value=":tags"
  per_section=3
%}
