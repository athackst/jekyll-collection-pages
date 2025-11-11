---
title: "Configuration guide"
category: "Reference"
description: "Reference for every collection_pages option, defaults, and validation tips."
order: 3
---

This guide describes the configuration options available in `jekyll-collection-pages` and how they interact. Use it as the single reference while wiring the plugin into your site.

## Overview

Add a `collection_pages` entry to `_config.yml`. Each entry targets one collection and one front-matter field:

```yaml
collection_pages:
  - collection: docs
    field: category
    path: docs/category
    layout: category_layout.html
    paginate: 6
```

You can declare multiple collections or multiple fields for the same collection by adding more entries to the array:

```yaml
collections:
  docs:
    output: true
  articles:
    output: true

collection_pages:
  - collection: docs
    field: category
    path: docs/category
    layout: category_layout.html
    paginate: 6
  - collection: articles
    field: tags
    path: articles/tags
    layout: tags_layout.html
    paginate: 10
```

If you only need a single entry, `collection_pages` can also be a hash (the plugin normalises it internally). The array form keeps things consistent once you add more targets.

## Configuration options

### `collection`

- Type: `String`  
- Required: ✔ 
- Description: Collection label from your `collections` configuration.

### `field`

- Type: `String`  
- Required: ✔  
- Description: Front-matter key used to group documents. Supports scalar values (e.g. `"category"`) and array values (e.g. `"tags"`).

Make sure every document you expect to index sets this field. When the field holds an array, the plugin creates one page per value.

### `path`

- Type: `String`  
- Required: ✔  
- Description: Destination directory (relative to the site source). Each unique field value is rendered under this path, e.g. `docs/category/getting-started/index.html`.

### `layout`

- Type: `String`  
- Required: ✖ (default: `collection_layout.html`)  
- Description: Layout file in `_layouts/` to render the generated page.

The plugin copies `page.posts`, `page.tag`, and optional `page.paginator` into the layout context.

### `paginate`

- Type: `Integer`  
- Required: ✖  
- Description: When present, splits the documents into pages of the given size. Pagination behaves like Jekyll’s built-in paginator (`page.paginator` exposes `page`, `total_pages`, `previous_page_path`, `next_page_path`, etc.) and the generated paths already include the tag directory (e.g. `docs/category/getting-started/`, `docs/category/getting-started/page2.html`), so piping them through `relative_url` yields working links.

Omit this key for single-page listings.

## Generated data

At build time the plugin exports `site.data.collection_pages[collection_name][field]`, which contains:

- `field`, `path`, `permalink` (`"#{path}/:#{field}"`)
- `pages` → `{ label => [documents...] }` (same shape as `site.tags`)
- `labels` → `{ label => { 'page', 'pages', 'path', 'layout', 'paginate' } }`

Use `pages` to feed existing includes, and `labels[label].page.url` when you need the generated index URL.

See the [Generated data reference](generated-data.md) for usage patterns and Liquid snippets.

## Validation tips

- Ensure the target collection has `output: true`, otherwise links from index pages may 404.
- Double-check that the `field` exists in every document; documents missing the field are skipped.
- Use `bundle exec jekyll build --trace` with `JEKYLL_LOG_LEVEL=debug` to see the plugin’s log output (e.g. total pages generated).
- Inspect `site.data.collection_pages` in a rendered page (`{% raw %}{{ site.data.collection_pages | jsonify }}{% endraw %}`) when debugging Liquid loops.

Ready to dive deeper? Explore the [examples](examples.md) for real-world configurations and the [layout recipes](layout-recipes.md) to customise the rendered pages.
