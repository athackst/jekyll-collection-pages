---
title: Advanced Usage and Examples
category: "Advanced Topics"
order: 4
---

This guide covers advanced usage scenarios and examples for the Jekyll Collection Pages plugin, including how to create an index page for your generated pages.

## Creating an Index Page for Generated Pages

To create an index page that lists all the generated category/tag pages:

1. Create a new layout file, e.g., `_layouts/collection_index.html`:

    ```html
    {% raw %}
    ---
    layout: default
    ---
    <h1>{{ page.title }}</h1>

    {% assign pages = site.pages | where: "layout", page.index_layout %}
    <ul>
    {% for p in pages %}
        <li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>
    {% endfor %}
    {% endraw %}
    </ul>
    ```

2. Create an index page, e.g., `categories.md` or `tags.md`:

    ```markdown
    ---
    layout: collection_index
    title: All Categories
    index_layout: category_layout
    permalink: /categories/
    ---
    ```

3. Update your `_config.yml` to use the new layout:

    ```yaml
    collection_pages:
    - collection: posts
        tag_field: category
        path: categories
        layout: category_layout.html
    ```

This setup will create an index page at `/categories/` that lists all category pages.

## Customizing Layouts

### Accessing Plugin-Specific Variables

In your layout files, you can access these variables:

- `page.tag`: The current tag/category
- `page.posts`: The posts for the current page
- `paginator.total_pages`: Total number of pages (if using pagination)
- `paginator.previous_page_path` and `paginator.next_page_path`: For pagination links

Example layout (`_layouts/category_layout.html`):

```html
{% raw %}
---
layout: default
---
<h1>Category: {{ page.tag }}</h1>

<ul>
  {% for post in page.posts %}
    <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
  {% endfor %}
</ul>

{% if paginator.total_pages > 1 %}
  {% if paginator.previous_page_path %}
    <a href="{{ paginator.previous_page_path | relative_url }}">Previous</a>
  {% endif %}
  <span>Page {{ paginator.page }} of {{ paginator.total_pages }}</span>
  {% if paginator.next_page_path %}
    <a href="{{ paginator.next_page_path | relative_url }}">Next</a>
  {% endif %}
{% endif %}
{% endraw %}
```

## Integrating with Other Jekyll Plugins

### With jekyll-seo-tag

Add this to your layout file:

```html
{% raw %}
{% seo title=false %}
<title>{{ page.tag }} - {{ site.title }}</title>
{% endraw %}
```

### With jekyll-sitemap

The generated pages will be automatically included in your sitemap. To exclude them, add to `_config.yml`:

```yaml
defaults:
  - scope:
      path: "categories"
    values:
      sitemap: false
```

## Performance Optimization

### Efficient Use of Liquid Tags

Use the `where` filter to reduce the number of items processed:

```liquid
{% raw %}
{% assign category_posts = site.posts | where: "category", page.tag %}
{% endraw %}
```

### Caching Strategies

Use the {% raw %}`{% capture %}`{% endraw %} tag to store complex computations:

```liquid
{% raw %}
{% capture category_list %}
  {% for post in site.posts %}
    {{ post.category | downcase }}
  {% endfor %}
{% endcapture %}
{% assign categories = category_list | split: ' ' | uniq | sort %}
{% endraw %}
```

## Multi-Language Support

To support multiple languages:

1. Create language-specific collections (e.g., `posts_en`, `posts_fr`)
2. Configure each collection separately:

```yaml
collection_pages:
  - collection: posts_en
    tag_field: category
    path: en/categories
    layout: category_en.html
  - collection: posts_fr
    tag_field: category
    path: fr/categories
    layout: category_fr.html
```

3. Create language-specific layouts (`category_en.html`, `category_fr.html`)

## Custom Sorting and Filtering

### Custom Sort Order

In your layout file:

```liquid
{% raw %}
{% assign sorted_posts = page.posts | sort: "custom_order" %}
{% for post in sorted_posts %}
  <!-- Display post -->
{% endfor %}
{% endraw %}
```

### Filtered Collection Pages

To create pages for a specific subset of your collection:

1. Add a custom field to your documents (e.g., `visibility: featured`)
2. In your layout, filter the posts:

```liquid
{% raw %}
{% assign featured_posts = page.posts | where: "visibility", "featured" %}
{% for post in featured_posts %}
  <!-- Display featured post -->
{% endfor %}
{% endraw %}
```

Remember to test these advanced configurations thoroughly, as they can interact in complex ways with your Jekyll site and other plugins.
