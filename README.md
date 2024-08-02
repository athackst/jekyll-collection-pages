---
title: "Quick start"
category: "Getting Started"
order: 1
---

## Usage

### Installation

Add this line to your Jekyll site's `Gemfile`:

```ruby
gem 'jekyll-collection-pages'
```

And add this line to your Jekyll site's `_config.yml`:

```yaml
plugins:
  - jekyll-collection-pages
```

### Basic Configuration

In your `_config.yml`, add the following configuration for each collection you want to generate pages for:

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

### Configuration Options

- `collection`: The name of the collection to generate pages for.
- `field`: The front matter field to use for categorization (e.g., 'category', 'tags').
- `path`: The output path for the generated pages.
- `layout`: The layout to use for the generated pages.
- `paginate`: (Optional) The number of items per page. If omitted, all items will be on a single page.

### Example Usage

1. **Setting up collections**

   In your `_config.yml`:

   ```yaml
   collections:
     docs:
       output: true
   collection_pages:
      collection: docs
      field: category
      path: docs/category
      layout: category_layout.html
      paginate: 6
   ```

2. **Creating collection items**

   Create files in your collections with appropriate front matter:

   `_docs/sample-doc.md`:
   ```yaml
   ---
   title: "Sample Document"
   category: "User Guide"
   ---
   This is a sample document.
   ```

   `_articles/sample-article.md`:
   ```yaml
   ---
   title: "Sample Article"
   tags: ["Jekyll", "Plugins"]
   ---
   This is a sample article.
   ```

3. **Creating layouts**

   Create layout files for your generated pages:

   `_layouts/category_layout.html`:
   ```html
   ---
   layout: default
   ---
   <h1>Category: {{ page.tag }}</h1>
   <ul>
   {% for post in page.posts %}
     <li><a href="{{ post.url }}">{{ post.title }}</a></li>
   {% endfor %}
   </ul>
   ```

4. **Accessing generated pages**

   The plugin will generate pages at paths like:
   - `/docs/category/user-guide.html`
   - `/articles/tags/jekyll.html`
   - `/articles/tags/plugins.html`

### Pagination

If you've set the `paginate` option, you can access pagination information in your layouts:

```html
{% if paginator.total_pages > 1 %}
  {% if paginator.previous_page %}
    <a href="{{ paginator.previous_page_path }}">Previous</a>
  {% endif %}
  <span>Page {{ paginator.page }} of {{ paginator.total_pages }}</span>
  {% if paginator.next_page %}
    <a href="{{ paginator.next_page_path }}">Next</a>
  {% endif %}
{% endif %}
```

### Demo Site

For more complex examples and a full working demo, check out the [demo site](https://www.althack.dev/jekyll-collection-pages) included in this repository.
