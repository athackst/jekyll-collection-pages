---
title: "Generated data reference"
category: "Reference"
description: "Learn the structure of site.data.collection_pages and use it to build custom indexes."
order: 4
---

The plugin exports data that mirrors Jekyll’s built-in `site.tags` and `site.categories` helpers, organized under a single hash. Use it to build dashboards, custom index pages, and sidebar navigation without re-walking `site.pages`.

## collection_pages

`site.data.collection_pages[collection][field]` returns a hash with:

- `template` → the full sanitized template used for creating pages with placeholders intact.  Directory-style values from `_config.yml` are auto-appended with `:field/page:num/index.html`. (e.g. `/docs/category/:field/page:num/index.html`)
- `permalink` → the sanitized template for the index with placeholders intact (e.g. `/docs/category/:field/`)
- `pages` → documents grouped by label (`{ label => [documents...] }`)
- `labels`: metadata describing the generated index pages

### pages

`pages` generates a list of documents grouped by label (`{ label => [documents...] }`)

Example:

```liquid
{% raw %}
{% assign info = site.data.collection_pages.articles.tags %}
{% for entry in info.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  <h2>{{ label }} ({{ documents.size }})</h2>
  <ul>
    {% for doc in documents %}
      <li><a href="{{ doc.url | relative_url }}">{{ doc.data.title }}</a></li>
    {% endfor %}
  </ul>
{% endfor %}
{% endraw %}
```

The structure is intentionally compatible with existing theme includes that expect `site.tags`.

### labels

`labels` exposes metadata about each generated index:

- `index`: the first generated index page (`index.html`)
- `pages`: array of all generated `TagPage` objects

Example:

```liquid
{% raw %}
## Index of generated pages
{%- assign index_by_label = site.data.collection_pages.docs.category.labels %}

{% for entry in index_by_label %}
  {% assign label = entry | first %}
  {% assign info = entry | last %}
  <h2> <a href="{{ info.index.url | relative_url }}">{{ label }}</a> ( {{ info.pages.size }})</h2>
  <ul>
  {% for entry in info.pages %}
    <li><a href="{{ entry.url }}">Page {{ entry.page_num }}</a></li>
  {% endfor %}
  </ul>
{% endfor %}
{% endraw %}
```

## Debugging tips

- Dump `site.data.collection_pages | jsonify` in a draft page to inspect the data structure during development (paths, permalinks, labels, and documents).  
- Enable debug logging (`JEKYLL_LOG_LEVEL=debug bundle exec jekyll build`) to see the list of generated labels.  
- When a label is missing, check the source documents for the configured field (case-sensitive).

Ready to render the maps? Jump to the [layout recipes](layout-recipes.md) for practical includes and UI patterns.
