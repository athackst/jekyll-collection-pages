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

Each `path` above is treated as a template—directory values automatically expand to `docs/<section>/categories/:field/page:num/index.html`. To switch to file-style permalinks, include the placeholders yourself, e.g. `docs/getting-started/categories/:field-page:num.html`.

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
- Description: Path template relative to the site source. It must contain exactly one `:field` placeholder (replaced with the slugified field value) and one `:num` placeholder (replaced with the page number). When you omit placeholders in a directory-style path, the plugin automatically appends them as `<path>/:field/page:num/index.html`. When you provide a filename (ends in `.html`/`.htm`), you must include both placeholders yourself. Leading/trailing slashes are stripped either way.

Rules enforced by the generator:

- `:field` must appear before `:num`, and they cannot be in the same path segment.
- Paths ending in `.html`/`.htm` must include both placeholders already.
- Leaving `path` blank defaults to `<collection>/:field/page:num/index.html`.

### `layout`

- Type: `String`  
- Required: ✖ (default: `collection_layout.html`)  
- Description: Layout file in `_layouts/` to render the generated page.

The plugin copies `page.posts`, `page.tag`, and optional `page.paginator` into the layout context.

### `paginate`

- Type: `Integer`  
- Required: ✖  
- Description: When present and positive, splits the documents into pages of the given size. Pagination behaves like Jekyll’s built-in paginator (`page.paginator` exposes `page`, `total_pages`, `previous_page_path`, `next_page_path`, etc.) and the generated paths already include the tag directory (e.g. `docs/category/getting-started/`, `docs/category/getting-started/page2.html`), so piping them through `relative_url` yields working links.

Set `paginate` to `nil`, omit the key, or use a non-positive number to render a single page per label. Non-numeric values raise an error during the build, so typos like `"ten"` fail fast.

## Generated data

At build time the plugin exports `site.data.collection_pages[collection_name][field]`, which contains:

- `template` → the full sanitized template used for creating pages with placeholders intact.  Directory-style values from `_config.yml` are auto-appended with `:field/page:num/index.html`. (e.g. `/docs/category/:field/page:num/index.html`)
- `permalink` → the sanitized template for the index with placeholders intact (e.g. `/docs/category/:field/`)
- `pages` → documents grouped by label (`{ label => [documents...] }`)
- `labels`: metadata describing the generated index pages

Use `pages` to feed existing includes, and `labels[label].index.url` when you need the generated index URL.

See the [Generated data reference](generated-data.md) for usage patterns and Liquid snippets.

## Validation tips

- Ensure the target collection has `output: true`, otherwise links from index pages may 404.
- Double-check that the `field` exists in every document; documents missing the field are skipped.
- Use `bundle exec jekyll build --trace` with `JEKYLL_LOG_LEVEL=debug` to see the plugin’s log output (e.g. total pages generated).
- Inspect `site.data.collection_pages` in a rendered page (`{% raw %}{{ site.data.collection_pages | jsonify }}{% endraw %}`) when debugging Liquid loops.

Ready to dive deeper? Explore the [examples](examples.md) for real-world configurations and the [layout recipes](layout-recipes.md) to customise the rendered pages.
