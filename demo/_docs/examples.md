---
title: "Example configurations"
category: "Usage"
description: "Copy-ready YAML and Liquid snippets for common collection setups."
order: 5
---

Use this cookbook to copy working `collection_pages` configurations and accompanying Liquid snippets.

## Blog categories

```yaml
collection_pages:
  - collection: posts
    field: category
    path: blog/category
    layout: category_page.html
    paginate: 10
```

This configuration will create category pages for your blog posts, with 10 posts per page.

Render a category listing with the exported data registry:

```liquid
{%raw %}
{% assign categories = site.data.collection_pages.posts.category %}
{% for entry in categories %}
  {% assign name = entry[0] %}
  {% assign docs = entry[1] %}
  <h2>{{ name }}</h2>
  <p>{{ docs.size }} posts</p>
{% endfor %}
{% endraw %}
```

## Documentation + tutorials

```yaml
collection_pages:
  - collection: docs
    field: section
    path: documentation/sections
    layout: doc_section.html
  - collection: tutorials
    field: difficulty
    path: tutorials/level
    layout: tutorial_level.html
    paginate: 6
```

This setup produces unpaginated doc sections and paginated tutorial difficulty indexes. Use the metadata map for quick links and pagination helpers:

```liquid
{% raw %}
{% assign tutorials_info = site.data.collection_pages.tutorials.difficulty %}
{% assign meta = tutorials_info.labels[label] %}
<a href="{{ meta.page.url | relative_url }}">View all tutorials for {{ label }}</a>
{% endraw %}
```

## Project tags

```yaml
collection_pages:
  - collection: projects
    field: tags
    path: portfolio/tags
    layout: project_tag.html
```

In your tag overview page:

```liquid
{% raw %}
{% assign projects_info = site.data.collection_pages.projects.tags %}
{% for entry in projects_info.pages %}
  {% assign label = entry | first %}
  {% assign items = entry | last %}
  {% assign meta = projects_info.labels[label] %}
  <a href="{{ meta.page.url | relative_url }}">{{ label }} ({{ items.size }})</a>
{% endfor %}
{% endraw %}
```

## One collection, multiple views

You can create pages based on multiple fields for the same collection:

```yaml
collection_pages:
  - collection: books
    field: genre
    path: books/genre
    layout: book_genre.html
  - collection: books
    field: author
    path: books/author
    layout: book_author.html
```

Use `site.data.collection_pages.books.genre.pages` and `site.data.collection_pages.books.author.pages` to populate dashboards, and `site.data.collection_pages.books.genre.labels[label].page.url` when you need the generated index URL.

## Image gallery collections

```yaml
collection_pages:
  - collection: gallery
    field: tags
    path: gallery/tags
    layout: gallery_tag.html
    paginate: 12
```

Overview pages can link to tag indexes via the metadata map, and each generated page exposes `page.paginator` for navigation:

```liquid
{% raw %}
{% assign gallery_info = site.data.collection_pages.gallery.tags %}
{% assign meta = gallery_info.labels[label] %}
<a href="{{ meta.page.url | relative_url }}">View all in {{ label }}</a>
{% endraw %}
```

```liquid
{% raw %}
{% if page.paginator %}
  <nav class="pager">
    {% if page.paginator.previous_page_path %}
      <a href="{{ page.paginator.previous_page_path | relative_url }}">Prev</a>
    {% endif %}
    <span>Page {{ page.paginator.page }} of {{ page.paginator.total_pages }}</span>
    {% if page.paginator.next_page_path %}
      <a href="{{ page.paginator.next_page_path | relative_url }}">Next</a>
    {% endif %}
  </nav>
{% endif %}
{% endraw %}
```

## Troubleshooting

- Ensure every collection lists `output: true` if you expect to link to its documents.
- Verify each document sets the `field` you configured (use `site.collections[collection].docs | map: "path"` to inspect).
- Confirm the layout file exists and uses `{{ page.posts }}` or `{{ page.paginator }}` as required.
- When debugging, dump `site.data.collection_pages | jsonify` in a temporary page to inspect the computed groups, metadata, and generated paths.
