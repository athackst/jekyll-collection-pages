---
title: "Using Jekyll for documentation"
date: 2024-08-02
author: Allison Thackston
image: /assets/img/post-img-2.png
tags: [jekyll, documentation, collections]
---

In the realm of technical documentation, content is king—but structure is the kingdom. A well-organized documentation site can make the difference between a frustrating user experience and an enlightening one. When users can easily find what they're looking for, whether through intuitive navigation or efficient search, they're more likely to engage with and benefit from your documentation.

Jekyll, with its flexibility and power, has long been a favorite tool for creating documentation sites. But when it comes to organizing complex documentation structures, especially those with multiple sections, nested categories, and interrelated content, even Jekyll can use a boost. This is where the Jekyll Collection Pages plugin shines, offering enhanced capabilities for structuring and organizing your content.

## Structuring Your Documentation Site

The foundation of a great documentation site is its structure. A well-planned structure makes navigation intuitive and helps users quickly find the information they need.

### Planning Your Content Hierarchy

Before diving into Jekyll configurations, take some time to plan your content hierarchy. Consider the following:

1. What are the main sections of your documentation?
2. Are there logical subsections within these main sections?
3. How might users expect to navigate through your content?

For example, a software documentation site might have a structure like this:

```
- Getting Started
  - Installation
  - Quick Start Guide
- User Guide
  - Basic Features
  - Advanced Features
- API Reference
- Troubleshooting
- FAQs
```

### Setting Up Collections

With your content hierarchy in mind, it's time to set up Jekyll collections. Collections in Jekyll allow you to group related content, which is perfect for documentation sites.

In your `_config.yml` file, define your collections:

```yaml
collections:
  getting_started:
    output: true
    permalink: /docs/getting-started/:path/
  user_guide:
    output: true
    permalink: /docs/user-guide/:path/
  api_reference:
    output: true
    permalink: /docs/api/:path/
  troubleshooting:
    output: true
    permalink: /docs/troubleshooting/:path/
```

### Utilizing Jekyll Collection Pages

Now, let's configure the Jekyll Collection Pages plugin to work with our structure. Add this to your `_config.yml`:

```yaml
collection_pages:
  - collection: getting_started
    tag_field: category
    path: docs/getting-started/categories
    layout: category_page.html
  - collection: user_guide
    tag_field: category
    path: docs/user-guide/categories
    layout: category_page.html
  - collection: api_reference
    tag_field: category
    path: docs/api/categories
    layout: category_page.html
  - collection: troubleshooting
    tag_field: category
    path: docs/troubleshooting/categories
    layout: category_page.html
```

This configuration tells the plugin to create category pages for each of our documentation sections.

### Example Structure

Let's look at how to implement this structure. Create directories for each collection in your Jekyll project:

```
_getting_started/
_user_guide/
_api_reference/
_troubleshooting/
```

Then, create Markdown files in these directories. For example, in `_getting_started/`:

```markdown
---
title: Installation
category: Setup
---

# Installation Guide

Here's how to install our software...
```

The Jekyll Collection Pages plugin will automatically create a category page at `/docs/getting-started/categories/setup.html` listing all documents in the "Setup" category.

## Implementing Effective Search

Even with the best structure, users often rely on search to find specific information quickly. Let's implement a search function using Lunr.js, a lightweight, full-text search library for client-side applications.

### Setting Up Lunr.js

First, add Lunr.js to your project. You can do this by adding the following to your default layout's `<head>` section:

```html
<script src="https://unpkg.com/lunr/lunr.js"></script>
```

Next, create a JSON file that Lunr.js will use as its search index. Add this to your `_config.yml`:

```yaml
plugins:
  - jekyll-collection-pages
  - jekyll-lunr-js-search
```

Create a `search.json` file in your root directory:

```liquid
{% raw %}
---
layout: null
---
[
  {% for collection in site.collections %}
    {% for doc in collection.docs %}
      {
        "title": {{ doc.title | jsonify }},
        "content": {{ doc.content | strip_html | jsonify }},
        "url": {{ doc.url | jsonify }}
      }{% unless forloop.last %},{% endunless %}
    {% endfor %}
  {% endfor %}
]
{% endraw %}
```

### Implementing the Search Interface

Create a search page (`search.html` in your root directory):

```html
{% raw %}
---
layout: default
title: Search
---

<h1>Search</h1>

<input type="text" id="search-input" placeholder="Search...">

<ul id="search-results"></ul>

<script>
  window.store = {
    {% for collection in site.collections %}
      {% for doc in collection.docs %}
        "{{ doc.url | slugify }}": {
          "title": "{{ doc.title | xml_escape }}",
          "content": {{ doc.content | strip_html | strip_newlines | jsonify }},
          "url": "{{ doc.url | xml_escape }}"
        }
        {% unless forloop.last %},{% endunless %}
      {% endfor %}
    {% endfor %}
  };
</script>
<script src="/path/to/lunr.min.js"></script>
<script src="/path/to/search.js"></script>
```

Create `search.js` in your JavaScript directory:

```javascript
(function() {
  function displaySearchResults(results, store) {
    var searchResults = document.getElementById('search-results');

    if (results.length) {
      var appendString = '';

      for (var i = 0; i < results.length; i++) {
        var item = store[results[i].ref];
        appendString += '<li><a href="' + item.url + '"><h3>' + item.title + '</h3></a>';
        appendString += '<p>' + item.content.substring(0, 150) + '...</p></li>';
      }

      searchResults.innerHTML = appendString;
    } else {
      searchResults.innerHTML = '<li>No results found</li>';
    }
  }

  function getQueryVariable(variable) {
    var query = window.location.search.substring(1);
    var vars = query.split('&');

    for (var i = 0; i < vars.length; i++) {
      var pair = vars[i].split('=');

      if (pair[0] === variable) {
        return decodeURIComponent(pair[1].replace(/\+/g, '%20'));
      }
    }
  }

  var searchTerm = getQueryVariable('query');

  if (searchTerm) {
    document.getElementById('search-box').setAttribute("value", searchTerm);

    var idx = lunr(function () {
      this.field('id');
      this.field('title', { boost: 10 });
      this.field('content');
    });

    for (var key in window.store) {
      idx.add({
        'id': key,
        'title': window.store[key].title,
        'content': window.store[key].content
      });
    }

    var results = idx.search(searchTerm);
    displaySearchResults(results, window.store);
  }
})();
{% endraw %}
```

## Leveraging Jekyll Collection Pages for Organization

The Jekyll Collection Pages plugin really shines when it comes to organizing your content. Let's explore some advanced uses.

### Automatic Category and Tag Pages

We've already set up basic category pages. Let's customize their layout. Create `_layouts/category_page.html`:

```html
{% raw %}
---
layout: default
---
<h1>{{ page.tag }}</h1>

<ul>
{% for post in page.posts %}
  <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
{% endfor %}
</ul>
{% endraw %}
```

### Creating a Dynamic Sidebar

Use collection data to generate a dynamic sidebar. Add this to your default layout:

```html
{% raw %}
<nav class="sidebar">
  {% for collection in site.collections %}
    {% if collection.label != "posts" %}
      <h3>{{ collection.label | capitalize | replace: "_", " " }}</h3>
      <ul>
        {% for doc in collection.docs %}
          <li><a href="{{ doc.url | relative_url }}">{{ doc.title }}</a></li>
        {% endfor %}
      </ul>
    {% endif %}
  {% endfor %}
{% endraw %}
</nav>
```

### Implementing Breadcrumbs

Add breadcrumbs to your document layout for easy navigation:

```html
{% raw %}
<div class="breadcrumbs">
  <a href="{{ '/' | relative_url }}">Home</a> &raquo;
  {% assign crumbs = page.url | split: '/' %}
  {% for crumb in crumbs offset: 1 %}
    {% if forloop.last %}
      {{ page.title }}
    {% else %}
      <a href="{{ site.baseurl }}{% assign crumb_limit = forloop.index | plus: 1 %}{% for crumb in crumbs limit: crumb_limit %}{{ crumb | append: '/' }}{% endfor %}">{{ crumb | replace: '-', ' ' | capitalize }}</a> &raquo;
    {% endif %}
  {% endfor %}
  {% endraw %}
</div>
```

### Cross-linking and Related Content

Utilize tags for suggesting related documents. In your document layout:

```html
{% raw %}
{% if page.tags %}
  <h3>Related Documents</h3>
  <ul>
    {% assign maxRelated = 4 %}
    {% assign minCommonTags =  1 %}
    {% assign maxRelatedCounter = 0 %}

    {% for doc in site.documents %}
      {% assign sameTagCount = 0 %}
      {% for tag in doc.tags %}
        {% if page.tags contains tag %}
          {% assign sameTagCount = sameTagCount | plus: 1 %}
        {% endif %}
      {% endfor %}
      {% if sameTagCount >= minCommonTags %}
        <li><a href="{{ doc.url | relative_url }}">{{ doc.title }}</a></li>
        {% assign maxRelatedCounter = maxRelatedCounter | plus: 1 %}
        {% if maxRelatedCounter >= maxRelated %}
          {% break %}
        {% endif %}
      {% endif %}
    {% endfor %}
  </ul>
{% endif %}
{% endraw %}
```

## Best Practices and Tips

1. **Consistent Front Matter**: Establish a template for front matter across your documents. This ensures consistency and makes it easier to implement site-wide features.

2. **Versioning Documentation**: For software documentation, consider using Git branches for different versions. You can then build separate sites for each version.

3. **Handling Images and Assets**: Store images in an `assets` folder within each collection. This keeps your content organized and makes it easy to move or refactor sections.

## Case Study: Refactoring an Existing Documentation Site

Let's say we have an existing documentation site with a flat structure, where all documents are in the `_posts` folder. Here's how we might refactor it:

Before:
```
_posts/
  2023-01-01-installation.md
  2023-01-02-quick-start.md
  2023-01-03-advanced-features.md
  2023-01-04-api-reference.md
  2023-01-05-troubleshooting.md
```

After:
```
_getting_started/
  installation.md
  quick-start.md
_user_guide/
  advanced-features.md
_api_reference/
  index.md
_troubleshooting/
  common-issues.md
```

This refactoring, combined with the Jekyll Collection Pages plugin configuration we discussed earlier, results in:

- Clearer content organization
- Automatically generated category pages
- Easier navigation with breadcrumbs and dynamic sidebar
- Improved search functionality

## Conclusion

By leveraging Jekyll's collection feature and the power of the Jekyll Collection Pages plugin, you can create a documentation site that's not only comprehensive but also user-friendly and easy to maintain. The key takeaways are:

1. Plan your content structure carefully
2. Use collections to organize your content logically
3. Implement search to help users find information quickly
4. Utilize the Jekyll Collection Pages plugin to automate category page creation and enhance organization
5. Implement features like breadcrumbs and related content to improve navigation

With these strategies in place, your Jekyll documentation site will be well-structured, easily navigable, and primed for growth. Happy documenting!
