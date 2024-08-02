---
title: "Linking Obsidian and Jekyll"
date: 2024-08-02
author: Allison Thackston
image: /assets/img/post-img-1.png
tags: [jekyll, obsidian, collections, symlinks, drafts]
---

As a long-time Obsidian user, I've fallen in love with its flexibility, linking capabilities, and the sheer joy of connecting ideas across my personal knowledge base. The way Obsidian allows me to create, organize, and interlink my thoughts is nothing short of revolutionary for my workflow. But there's been one persistent itch I've wanted to scratch: how can I easily share select parts of my Obsidian vault with the world?

Enter Jekyll, the static site generator that's been a staple for developers and bloggers alike. Jekyll's power in creating fast, efficient websites is undeniable. However, the traditional Jekyll setup, with its focus on the _posts directory and specific naming conventions, always felt at odds with my Obsidian workflow. The thought of manually renaming files, adjusting front matter, and maintaining two separate systems for my notes was, frankly, exhausting.

What I needed was a bridge between these two worlds - a way to harness Obsidian's note-taking prowess and Jekyll's publishing capabilities without compromising either. I wanted to write in Obsidian as I always have, with my preferred file names and organization, and then seamlessly publish select notes to my Jekyll site without any file juggling or renaming gymnastics.

That's where this setup comes in. By leveraging Jekyll collections, smart use of symlinks, and the power of the Jekyll Collection Pages plugin, we can create a harmonious workflow that respects the Obsidian structure while unlocking Jekyll's publishing potential.


## Creating the Symlink

1. Open your terminal.
2. Navigate to your Jekyll site's root directory.
3. Create a symlink from your Obsidian vault to a Jekyll collection:

   ```bash
   ln -s /path/to/your/obsidian/vault /path/to/your/jekyll/_articles
   ```

   Replace `/path/to/your/obsidian/vault` with the actual path to your Obsidian vault, and `/path/to/your/jekyll/_articles` with the path where you want the collection in your Jekyll site.

## Setting Up the Collection

1. In your Jekyll `_config.yml`, add:

   ```yaml
   collections:
     articles:
       output: true
   ```

2. Create a default layout for articles in `_layouts/article.html`.

## Enabling Tags

1. In `_config.yml`, add:

   ```yaml
   collection_pages:
     - collection: articles
       tag_field: tags
       path: tags
       layout: tag_layout.html
   ```

2. Create `_layouts/tag_layout.html` for your tag pages.

## Managing Drafts

1. In `_config.yml`, add a default front matter for articles:

   ```yaml
   defaults:
     - scope:
         path: ""
         type: "articles"
       values:
         layout: "article"
         published: false
   ```

2. In Obsidian, add to your note's front matter to publish:

   ```yaml
   ---
   published: true
   ---
   ```

## Usage

1. Write your notes in Obsidian as usual.
2. Add tags in Obsidian using `#tag` syntax or in the front matter.
3. When ready to publish, add `published: true` to the note's front matter.
4. Build your Jekyll site – only published articles will appear.

This setup allows you to seamlessly use Obsidian for note-taking while leveraging Jekyll's powerful publishing features. The Jekyll Collection Pages plugin handles tag organization, making your content easily navigable.

Remember to gitignore the symlinked directory to avoid committing your entire Obsidian vault!

Happy writing and publishing!
