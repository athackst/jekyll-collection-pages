---
layout: page
style: stacked
title: Jekyll Collection Pages Demo
---

# Welcome to the Jekyll Collection Pages Plugin Demo

Discover how Jekyll Collection Pages can transform your site's organization and navigation.

## What is Jekyll Collection Pages?

Jekyll Collection Pages is a powerful plugin that enhances Jekyll's built-in collections feature. It allows you to:

- Automatically generate category and tag pages for your collections
- Create custom layouts for different types of content
- Implement pagination for your collection pages
- Organize your content with unprecedented flexibility

## Explore Our Demo

### 📚 Documentation
See how Jekyll Collection Pages organizes technical documentation:
- [Browse Documentation](docs.md)
- [View Documentation Categories](category.md)

### 📝 Articles
Explore our blog-style content organization:

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

## Get Started

Ready to use Jekyll Collection Pages in your own project?

1. [Quick Start Tutorial](_docs/quick-start.md)
2. [Configuration Guide](_docs/configuration-guide.md)
3. [Advanced Usage Tips](_docs/advanced-usage.md)

## Community and Support

- [GitHub Repository](https://github.com/athackst/jekyll-collection-pages)
- [Report an Issue](https://github.com/athackst/jekyll-collection-pages/issues)
- [Contribution Guidelines](contributing.md)

We hope this demo site helps you understand the power and flexibility of Jekyll Collection Pages. Happy exploring!
