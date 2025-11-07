---
title: Layout recipes
category: "Usage"
description: "Practical Liquid patterns for rendering collection indexes, pagination, and integrations."
order: 6
---

Use these recipes to tailor the generated pages, hook into pagination, or integrate with other plugins.

## Category/tag layout template

```html
{% raw %}
---
layout: default
---
<header class="collection-header">
  <h1>{{ page.tag }}</h1>
  <p>{{ page.posts | size }} items</p>
</header>

<section class="collection-grid">
  {% for doc in page.posts %}
    <article class="collection-card">
      <h2><a href="{{ doc.url | relative_url }}">{{ doc.data.title }}</a></h2>
      <p>{{ doc.data.excerpt }}</p>
    </article>
  {% endfor %}
</section>

{% if page.paginator %}
  <nav class="collection-pagination">
    {% if page.paginator.previous_page_path %}
      <a href="{{ page.paginator.previous_page_path | relative_url }}">Previous</a>
    {% endif %}
    <span>Page {{ page.paginator.page }} of {{ page.paginator.total_pages }}</span>
    {% if page.paginator.next_page_path %}
      <a href="{{ page.paginator.next_page_path | relative_url }}">Next</a>
    {% endif %}
  </nav>
{% endif %}
{% endraw %}
```

## “View all” links from an overview page

```liquid
{% raw %}
{% assign info = site.data.collection_pages.docs.category %}

{% for entry in info.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  {% assign meta = info.labels[label] %}
  <div class="category-summary">
    <h2>{{ label }}</h2>
    <p>{{ documents.size }} docs</p>
    <a href="{{ meta.page.url | relative_url }}">View all</a>
  </div>
{% endfor %}
{% endraw %}
```

## Dynamic includes

If you already have a `post-index.html` include that expects `site.tags`-style input, the plugin’s data map just works. Pass the metadata map when you want each section to know its generated URL:

```liquid
{% raw %}
{% include post-index.html
   collection=site.data.collection_pages.articles.tags.pages
   collection_permalink="/articles/tags/:tag"
   replace_value=":tag"
   meta=site.data.collection_pages.articles.tags.labels %}
{% endraw %}
```

## SEO & sitemap integration

`jekyll-seo-tag` reads `page.title`, so set it for nicer previews:

```html
{% raw %}
---
layout: default
title: "{{ page.tag }} – {{ site.title }}"
---
{% seo title=false %}
{% endraw %}
```

`jekyll-sitemap` includes generated pages automatically. To exclude a path:

```yaml
defaults:
  - scope:
      path: "docs/category"
    values:
      sitemap: false
```

## Multilingual layouts

When you maintain per-language collections, add a language code to your layouts:

```liquid
{% raw %}
{% assign fr_info = site.data.collection_pages.docs_fr.category %}
{% assign fr_page = fr_info.labels[page.tag] %}
{% if fr_page %}
  <link rel="alternate" hreflang="fr" href="{{ fr_page.page.url | relative_url }}">
{% endif %}
{% endraw %}
```

## Performance hints

- Use the exported data maps instead of iterating over `site.pages` to find generated pages.
- When rendering large grids, pre-sort with Liquid filters.
- Cache expensive loops in includes using capture if they are reused in multiple sections.
