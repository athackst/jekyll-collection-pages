---
title: "Example configurations"
category: "Advanced Topics"
order: 2
---

These examples provide references for various configurations you can use for  Jekyll Collection Pages plugin to suit youro needs.

## Basic Blog with Categories

```yaml
collection_pages:
  - collection: posts
    field: category
    path: blog/category
    layout: category_page.html
    paginate: 10
```

This configuration will create category pages for your blog posts, with 10 posts per page.

## Documentation with Multiple Collections

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
    paginate: 5
```

This setup creates unpaginated section pages for documentation and paginated difficulty level pages for tutorials

## Project Portfolio with Tags

```yaml
collection_pages:
  - collection: projects
    field: tags
    path: portfolio/tags
    layout: project_tag.html
```

This configuration creates tag pages for a project portfolio, allowing visitors to brows projects by tag.

## Multiple Fields for a Single Collection

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

This configuration creates separate pages for browsing books by genre and author.

## Troubleshooting

- Ensure your collection is properly defined in your Jekyll configuration
- Check that the specified `field` exists in your document front matter
- Verify that the specified layout file exists in your `_layouts` directory.
