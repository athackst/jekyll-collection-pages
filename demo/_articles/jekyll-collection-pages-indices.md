---
layout: post
title: "Generate Index Pages from Your Jekyll Collections"
date: 2025-11-10
author: Allison Thackston
tags: [jekyll, plugins, collections, pagination, releases]
image: /assets/img/post-img-4.png
description: "Introducing automated collection index pages with site.data.collection_pages"
---

The latest release of **`jekyll-collection-pages`** introduces a new way to **generate index pages automatically** for any Jekyll collection.  
Define one simple configuration, and the plugin creates organized, linkable index pages for every unique value of a chosen field — such as `category`, `tags`, or any custom key.

## What It Does

Until now, creating index pages for collections meant writing a custom generator or manually duplicating layouts.  
With this release, the plugin can now:

- Build one index page per unique field value  
- Paginate results automatically  
- Expose a structured dataset in `site.data.collection_pages` for custom UIs  

That means you can create browsable directories like:

```
/docs/category/getting-started/
/docs/category/reference/
/docs/category/usage/
```

All without writing a single custom generator.


## Quick Start

In your `_config.yml`, define the behavior for your collection under `collection_pages`:

```yaml
collection_pages:
  collection: docs
  field: category
  path: docs/category
  layout: collection_layout.html
  paginate: 5
```

Then rebuild your site:

```bash
bundle exec jekyll build
```

You’ll find generated pages under `_site/docs/category/<slug>/index.html` — one folder per unique `category` value.  
If you specify `paginate`, the plugin creates additional pages that follow the template (e.g. `/docs/category/getting-started/page2/`) and exposes previous/next links via `page.paginator`.


## Generated Data Reference

Every run exports metadata into `site.data.collection_pages`, mirroring Jekyll’s built-in `site.tags` and `site.categories`.

```liquid
{% raw %}
site.data.collection_pages[collection][field]
{% endraw %}
```

Each entry includes:

- `template` → the full sanitized template used for creating pages with placeholders intact.  Directory-style values from `_config.yml` are auto-appended with `:field/page:num/index.html`. (e.g. `/docs/category/:field/page:num/index.html`)
- `permalink` → the sanitized template for the index with placeholders intact (e.g. `/docs/category/:field/`)
- `pages` → documents grouped by label (`{ label => [documents...] }`)
- `labels`: metadata describing the generated index pages

### pages

Groups documents by label:

```liquid
{% raw %}
{% assign info = site.data.collection_pages.docs.category %}
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

### labels

Provides metadata for each generated index:

- `index`: first generated index page (`index.html`)
- `pages`: all generated index pages (if paginated)

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

## Example Layout

Here’s a minimal `collection_layout.html` template:

```html
---
layout: default
---

<h1>{{ page.title }}</h1>

<ul>
  {% for post in page.posts %}
    <li><a href="{{ post.url }}">{{ post.data.title }}</a></li>
  {% endfor %}
</ul>

{% if page.paginator %}
  <nav>
    {% if page.paginator.previous_page %}
      <a href="{{ page.paginator.previous_page_path | relative_url }}">Previous</a>
    {% endif %}
    {% if page.paginator.next_page %}
      <a href="{{ page.paginator.next_page_path | relative_url }}">Next</a>
    {% endif %}
  </nav>
{% endif %}
```

`page.paginator.previous_page_path` and `page.paginator.next_page_path` already contain the tag directory (for example `docs/category/reference/` or `docs/category/reference/page2.html`), so passing them through `relative_url` is enough to produce correct links.

---

## Debugging and Development Tips

- Dump the full structure with `{% raw %}{{ site.data.collection_pages | jsonify }}{% endraw %}`  
- Enable debug logging:  
  ```bash
  JEKYLL_LOG_LEVEL=debug bundle exec jekyll build
  ```
- Check field names for case sensitivity — missing labels usually indicate a typo or inconsistent field key.

---

## Why It Matters

This feature bridges the gap between Jekyll’s **collections** and **taxonomy-style browsing**, enabling:

- Documentation sites with sectioned navigation  
- Blogs organized by topic or author  
- Paginated directories of any custom field  

No manual duplication, no custom Liquid loops — just configuration.
