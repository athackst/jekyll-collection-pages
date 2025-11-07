---
title: "Quick start"
category: "Getting Started"
description: "Install the plugin, configure your first collection, and explore the generated pages."
order: 2
---

`jekyll-collection-pages` adds automated index pages, layout selection, and optional pagination for any Jekyll collection. In a few minutes you can stand up front-matter key based landing pages like "tags" or "categories" that stay in sync with your content.

## Install the plugin

1. Add the gem to your site’s `Gemfile`:

    ```ruby
    gem 'jekyll-collection-pages'
    ```

2. Enable the plugin in `_config.yml`:

    ```yaml
    plugins:
      - jekyll-collection-pages
    ```

3. Ensure the collections you plan to index have `output: true` so the generated pages can link to the documents.

## Configure your first collection

Add a `collection_pages` entry for each collection/field combination you want to index:

```yaml
collections:
  docs:
    output: true

collection_pages:
  - collection: docs
    field: category
    path: docs/category
    layout: category_layout.html
    paginate: 6
```

Key options:
- `collection`: collection label (matches `collections` config).
- `field`: front-matter key to group documents (string or list values).
- `path`: base folder for generated pages (relative to site root).
- `layout`: layout in `_layouts/` (defaults to `collection_layout.html`).
- `paginate`: optional integer for per-page pagination.

You can declare multiple entries—single collection with many fields, or multiple collections:

```yaml
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

## Build and explore

Run `bundle exec jekyll serve` and visit the generated paths, e.g. `/docs/category/getting-started/`. The plugin injects these variables into layouts:

- `page.tag`: value of the current field.
- `page.posts`: documents in that field bucket.
- `page.paginator`: pagination data when `paginate` is set (same shape as Jekyll paginator).


```html
{% raw %}
---
layout: default
---
<h1>{{ page.tag }}</h1>
<ul>
  {% for doc in page.posts %}
    <li><a href="{{ doc.url | relative_url }}">{{ doc.data.title }}</a></li>
  {% endfor %}
</ul>
{% endraw %}
```

## Surface the generated data

Every build populates a hash at `site.data.collection_pages[collection][field]` that contains:

- `field`, `path`, and `permalink`: the configuration details
- `pages`: documents grouped by label (same shape as `site.tags`)
- `labels`: metadata describing the generated index pages

Iterate through the documents for a field:

```liquid
{% raw %}
{% assign docs_info = site.data.collection_pages.docs.category %}
{% for entry in docs_info.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  <h2>{{ label }}</h2>
  <p>{{ documents.size }} docs</p>
{% endfor %}
{% endraw %}
```

Pair the documents with their metadata when you need generated URLs or pagination helpers:

```liquid
{% raw %}
{%- assign info = site.data.collection_pages.articles.tags %}

{% for entry in info.pages %}
  {% assign label = entry | first %}
  {% assign documents = entry | last %}
  {% assign meta = info.labels[label] %}
  <h2> <a href="{{ meta.page.url | relative_url }}">{{ label }}</a> ({{ documents.size }})</h2>
  <ul>
  {% for entry in documents %}
    <li><a href="{{ entry.url }}">{{ entry.title }}</a></li>
  {% endfor %}
  </ul>
{% endfor %}
{% endraw %}
```
