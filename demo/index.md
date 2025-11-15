---
layout: page
style: stacked
title: jekyll-collection-pages demo
---

# Welcome to the jekyll-collection-pages Demo

Discover how jekyll-collection-pages can transform your site's organization and navigation.

## What is jekyll-collection-pages?

`jekyll-collection-pages` is a powerful plugin that enhances Jekyll's built-in collections feature. It allows you to:

- Automatically generate category and tag pages for your collections
- Create custom layouts for different types of content
- Implement pagination for your collection pages
- Organize your content with unprecedented flexibility

## Explore

### Documentation

See how `jekyll-collection-pages` organizes technical documentation:
- [Browse Documentation](docs.md)

### Articles

See how `jekyll-collection-pages` can organize collections like posts:

- [Tag directory](directory.md)
- [Tag index](tags.md)
- [Tag gallery](gallery.md)

## Get Started

Ready to use `jekyll-collection-pages` in your own project?

1. [Quick Start Tutorial](_docs/quick-start.md)
2. [Configuration Guide](_docs/configuration-guide.md)
3. [Troubleshooting and Tips](_docs/troubleshooting.md)

## News

<div class="d-flex flex-wrap gutter-spacious">
{%- assign latest_posts = site.articles | sort: "date" | reverse %}
<!-- This loops through the articles -->
{%- for post in latest_posts limit: 3 %}
  {%- if post.feature or post == site.posts[0] %}
  {%- include post-feature-card.html %}
  {%- else %}
  {%- include post-card.html border="border-top" %}
  {%- endif %}
{% endfor %}
</div>>



## Community and Support

- [GitHub Repository](https://github.com/athackst/jekyll-collection-pages)
- [Report an Issue](https://github.com/athackst/jekyll-collection-pages/issues)
- [Contribution Guidelines](contributing.md)
