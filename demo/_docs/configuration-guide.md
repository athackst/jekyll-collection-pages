---
title: "Configuration guide"
category: "Advanced Topics"
order: 3
---

This guide provides detailed information on how to configure the Jekyll Collection Pages plugin to suit youro needs

## Overview

The Jekyll Collection Pages plugin is configured in your site's `_config.yml` file.  The basic structure of the configuration is as follows

```yaml

collection_pages:
    collection: docs
    field: category
    path: docs/category
    layout: category_layout.html
    paginate: 6
```

You can also configure multiple collections by using an array


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

## Configuration options

### `collection`

- Type: string
- Required: Yes
- Description: The name of the collection to generate pages for.

This should match the name of a collection defined in your Jekyll site configuration.

### `field`

- Type: String
- Required: Yes
- Description: The front matter field to use for generating pages

This field should exist in the front matter of your collection documents.  If using a field that can contain multiple values (like `tags`), the plugin will creat a page for each unique value.

### `path`

- Type: String
- Required: Yes
- Description: The output path for generated pages

This determines where the generated pages will be placed in your site structure. The plugin will create subdirectories here for each unique field entry.

### `layout`

- Type: String
- Required: No (default: collection_layout.html)
- Description: The layout to use for the generated pages

This should be the name of a layout file in your `_layouts` directory.

### `paginate`

- Type: Integer
- Required: No (default: None)
- Description: The number of items to display per page

If set, the plugin will create paginated pages.  If omitted, all items will be displayed on a single page.
