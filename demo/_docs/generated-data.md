---
title: "Generated data reference"
category: "Reference"
description: "Learn the structure of site.data.collection_pages and use it to build custom indexes."
order: 4
---

The plugin exports data that mirrors Jekyll’s built-in `site.tags` and `site.categories` helpers, organized under a single hash. Use it to build dashboards, custom index pages, and sidebar navigation without re-walking `site.pages`.

## collection_pages

`site.data.collection_pages[collection][field]` returns a hash with:

- `field`, `path`, `permalink`
- `pages` → documents grouped by label (`{ label => [documents...] }`)
- `labels` → metadata for the generated index pages

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

- `page`: the first generated index page (`index.html`)
- `pages`: array of all `TagIndexPage` objects (when paginated)
- `path`: base path for the label
- `layout`: layout basename
- `paginate`: configured per-page value (or `nil`)

Example:

```liquid
{% raw %}
{% assign info = site.data.collection_pages.articles.tags %}

{% for entry in info.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  {% assign meta = info.labels[label] %}
  <h2>{{ label }} ({{ documents.size }})</h2>
  <p>Permalink template: {{ info.permalink }}</p>
  <a href="{{ meta.page.url | relative_url }}">View all</a>
  {% if meta.paginate %}
    <small>Paginated ({{ meta.paginate }} per page)</small>
  {% endif %}
{% endfor %}
{% endraw %}
```

## Debugging tips

- Dump `site.data.collection_pages | jsonify` in a draft page to inspect the data structure during development (paths, permalinks, labels, and documents).  
- Enable debug logging (`JEKYLL_LOG_LEVEL=debug bundle exec jekyll build`) to see the list of generated labels.  
- When a label is missing, check the source documents for the configured field (case-sensitive).

Ready to render the maps? Jump to the [layout recipes](layout-recipes.md) for practical includes and UI patterns.
