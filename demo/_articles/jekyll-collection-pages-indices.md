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

You’ll find generated pages under `_site/docs/category/...` — one folder per unique `category` value.  
If you specify `paginate`, the plugin will also create additional pages (`page2.html`, etc.) with navigation links.


## Generated Data Reference

Every run exports metadata into `site.data.collection_pages`, mirroring Jekyll’s built-in `site.tags` and `site.categories`.

```liquid
{% raw %}
site.data.collection_pages[collection][field]
{% endraw %}
```

Each entry includes:

- `field`, `path`, `permalink`
- `pages` → documents grouped by label (`{ label => [documents...] }`)
- `labels` → metadata for the generated index pages

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

- `page`: first generated index page (`index.html`)
- `pages`: all generated index pages (if paginated)
- `path`: base output path
- `layout`: layout basename
- `paginate`: configured per-page value (or `nil`)

Example:

```liquid
{% raw %}
{% assign info = site.data.collection_pages.docs.category %}
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
