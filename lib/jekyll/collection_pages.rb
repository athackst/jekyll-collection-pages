# frozen_string_literal: true

module Jekyll
  module CollectionPages
    INDEXFILE = 'index.html'

    class TagPagination < Generator
      safe true
      priority :lowest

      def generate(site)
        return unless site.config['collection_pages']

        config = site.config['collection_pages']

        if config.is_a?(Hash)
          Jekyll.logger.debug('CollectionPages:', 'Processing single collection config')
          generate_for_config(site, config)
        elsif config.is_a?(Array)
          Jekyll.logger.debug('CollectionPages:', 'Processing multiple collection config')
          config.each do |collection_config|
            generate_for_config(site, collection_config)
          end
        end
        Jekyll.logger.debug('CollectionPages:', "Generation complete. Total pages: #{site.pages.size}")
      end

      def generate_for_config(site, config)
        collection_name = config['collection']
        tag_field = config['field']
        tag_base_path = config['path']
        tag_layout = config['layout'] || 'collection_layout.html'
        per_page = config['paginate']

        tag_layout_path = File.join('_layouts/', tag_layout)

        site.data['collection_pages'] ||= {}

        Jekyll.logger.debug('CollectionPages:', "Generating pages for collection: #{collection_name}")
        documents_map, metadata_map = if per_page
                                        generate_paginated_tags(site, tag_base_path, tag_layout_path, collection_name, tag_field, per_page)
                                      else
                                        generate_tags(site, tag_base_path, tag_layout_path, collection_name, tag_field)
                                      end

        collection_registry = site.data['collection_pages'][collection_name] ||= {}
        collection_registry[tag_field] = {
          'field' => tag_field,
          'path' => tag_base_path,
          'permalink' => "#{tag_base_path}/:#{tag_field}",
          'labels' => metadata_map,
          'pages' => documents_map
        }
      end

      def sorted_tags(site, collection_name, tag_field)
        tags = {}
        collection = site.collections[collection_name]
        return [] unless collection

        Jekyll.logger.debug('CollectionPages:', "Found colleciton '#{collection_name}' with #{collection.docs.size} entries.")
        collection.docs.each do |doc|
          doc_tags = doc.data[tag_field]
          next unless doc_tags

          doc_tags = [doc_tags] if doc_tags.is_a?(String)
          doc_tags.each do |tag|
            tags[tag] ||= []
            tags[tag] << doc
          end
        end
        tags.keys.sort!
      end

      def generate_paginated_tags(site, tag_base_path, tag_layout, collection_name, tag_field, per_page)
        tags = sorted_tags(site, collection_name, tag_field)

        documents_map = {}
        metadata_map = {}

        tags.each do |tag|
          posts_with_tag = site.collections[collection_name].docs.select do |doc|
            doc_tags = doc.data[tag_field]
            doc_tags && (doc_tags.is_a?(String) ? doc_tags == tag : doc_tags.include?(tag))
          end
          tag_path = File.join(tag_base_path, Utils.slugify(tag))

          page_count = TagPager.calculate_pages(posts_with_tag, per_page)
          tag_pages = []
          (1..page_count).each do |page_num|
            tag_page = TagIndexPage.new(site, tag_path, page_num, tag, tag_layout, posts_with_tag, true, per_page)
            site.pages << tag_page
            tag_pages << tag_page
          end

          documents_map[tag] = posts_with_tag
          metadata_map[tag] = {
            'pages' => tag_pages,
            'page' => tag_pages.first,
            'path' => tag_path,
            'layout' => File.basename(tag_layout, '.*'),
            'paginate' => per_page
          }
        end

        Jekyll.logger.info('CollectionPages:',
                           "Generated #{tags.size} paginated index pages for collection '#{collection_name}' with field '#{tag_field}'")
        Jekyll.logger.debug('CollectionPages:', "Pages made for: #{tags.inspect}")

        [documents_map, metadata_map]
      end

      def generate_tags(site, tag_base_path, tag_layout, collection_name, tag_field)
        tags = sorted_tags(site, collection_name, tag_field)

        documents_map = {}
        metadata_map = {}

        tags.each do |tag|
          posts_with_tag = site.collections[collection_name].docs.select do |doc|
            doc_tags = doc.data[tag_field]
            doc_tags && (doc_tags.is_a?(String) ? doc_tags == tag : doc_tags.include?(tag))
          end
          tag_path = File.join(tag_base_path, Utils.slugify(tag))
          tag_page = TagIndexPage.new(site, tag_path, 1, tag, tag_layout, posts_with_tag, false, nil)
          site.pages << tag_page
          documents_map[tag] = posts_with_tag
          metadata_map[tag] = {
            'pages' => [tag_page],
            'page' => tag_page,
            'path' => tag_path,
            'layout' => File.basename(tag_layout, '.*'),
            'paginate' => nil
          }
        end

        Jekyll.logger.info('CollectionPages:', "Generated #{tags.size} index pages for collection '#{collection_name}'")
        Jekyll.logger.debug('CollectionPages:', "Pages made for: #{tags.inspect}")

        [documents_map, metadata_map]
      end
    end
  end

  class TagIndexPage < Page
    def initialize(site, dir, page_num, tag, tag_layout, posts_with_tag, use_paginator, per_page)
      @site = site
      @base = site.source
      if !File.exist?(File.join(@base, tag_layout)) &&
         site.theme && File.exist?(File.join(site.theme.root, tag_layout))
        @base = site.theme.root
      end

      super(site, @base, '', tag_layout)
      @dir = dir
      @name = page_num == 1 ? CollectionPages::INDEXFILE : "page#{page_num}.html"

      process(@name)

      read_yaml(@base, tag_layout)

      data['layout'] = File.basename(tag_layout, '.*')
      data['tag'] = tag
      data['title'] = tag.to_s
      data['posts'] = posts_with_tag

      return unless use_paginator

      total_pages = TagPager.calculate_pages(posts_with_tag, per_page)
      paginator = TagPager.new(page_num, per_page, posts_with_tag)
      paginator.set_previous_next(total_pages)
      data['paginator'] = paginator
    end
  end

  class TagPager
    attr_reader :page, :per_page, :posts, :total_posts, :total_pages,
                :previous_page, :previous_page_path, :next_page, :next_page_path

    def self.calculate_pages(all_posts, per_page)
      (all_posts.size.to_f / per_page.to_i).ceil
    end

    def initialize(page, per_page, all_posts)
      @page = page
      @per_page = per_page
      @total_posts = all_posts.size
      @total_pages = self.class.calculate_pages(all_posts, per_page)

      init = (page - 1) * per_page
      offset = [init + per_page - 1, total_posts - 1].min
      @posts = all_posts[init..offset]
    end

    def set_previous_next(total_pages)
      @previous_page = @page > 1 ? @page - 1 : nil
      @next_page = @page < total_pages ? @page + 1 : nil
      @previous_page_path = if @previous_page
                              @previous_page == 1 ? 'index.html' : "page#{@previous_page}.html"
                            end
      @next_page_path = @next_page ? "page#{@next_page}.html" : nil
    end

    def to_liquid
      {
        'page' => @page,
        'per_page' => @per_page,
        'posts' => @posts,
        'total_posts' => @total_posts,
        'total_pages' => @total_pages,
        'previous_page' => @previous_page,
        'previous_page_path' => @previous_page_path,
        'next_page' => @next_page,
        'next_page_path' => @next_page_path
      }
    end
  end
end
