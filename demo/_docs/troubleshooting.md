---
title: Troubleshooting & FAQ
category: "Reference"
description: "Diagnose common issues and learn how to inspect the plugin’s output."
order: 7
---

Having trouble seeing generated pages or data? Start here.

## Pages not created

- Ensure the target collection is defined with `output: true`.
- Confirm the `collection_pages` entry uses the correct collection name and field spelling.
- Run `JEKYLL_LOG_LEVEL=debug bundle exec jekyll build` to view the plugin’s log lines. They list each collection processed and how many pages were generated.

## Missing tags or categories

- Dump the data registry in a draft page:

  ```liquid
  {% raw %}
  <pre>{{ site.data.collection_pages | jsonify }}</pre>
  {% endraw %}
  ```

  If the label is missing, double-check the source document’s front matter.

- Remember that string fields are case-sensitive (`"Docs"` and `"docs"` create different pages).

## Pagination navigation broken

- When using `paginate`, render pagination links with `page.paginator.previous_page_path` and `page.paginator.next_page_path`. The plugin now emits paths that already include the generated tag/category directory (e.g. `docs/category/reference/`), so piping them through `relative_url` produces working absolute URLs.
- Verify the configured `paginate` value is a positive integer. Non-numeric values raise an error and zero/negative values fall back to single-page generation.
- To link back to the first page, use the page directory:

  ```liquid
  {% raw %}
  <a href="{{ page.dir | append: '/' | relative_url }}">Back to first page</a>
  {% endraw %}
  ```

## Liquid include expects `site.tags`

- Pass the plugin’s document map directly:

  ```liquid
  {% raw %}
  {% include post-index.html collection=site.data.collection_pages.docs.category %}
  {% endraw %}
  ```

- If the include also needs the generated page URL, read `site.data.collection_pages[collection][field].labels[label].page.url` (or build it from the configured `path` plus the slugified label).

## Layout doesn’t see `page.posts`

- Make sure the layout file starts with front matter (`---` lines). Without it, Jekyll treats it as a static file and skips Liquid rendering.
- The variable is `page.posts` (not `page.documents`). When pagination is enabled, it shows only the current page’s slice; use `page.paginator.total_posts` for the total count.

## Still stuck?

- Open an issue with your `_config.yml` snippet and the relevant front matter.
- Compare your site with the demo in this repository (`demo/` directory) to spot structural differences.
