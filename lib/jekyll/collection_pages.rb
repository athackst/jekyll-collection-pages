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
        per_page = normalize_paginate_value(config['paginate'], collection_name, tag_field)

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
            paginator = TagPager.new(page_num, per_page, posts_with_tag)
            paginator.update_navigation(page_count)
            tag_page = build_page(site, tag_path, page_num, tag, tag_layout, paginator.posts, paginator)
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
          tag_page = build_page(site, tag_path, 1, tag, tag_layout, posts_with_tag)
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

      def build_page(site, dir, page_number, tag, layout, posts, paginator = nil)
        TagIndexPage.new(
          site,
          {
            dir: dir,
            page_number: page_number,
            tag: tag,
            layout: layout,
            posts: posts,
            paginator: paginator
          }
        )
      end

      private

      def normalize_paginate_value(value, collection_name, tag_field)
        return nil if value.nil?

        per_page = Integer(value)
        return per_page if per_page.positive?

        Jekyll.logger.warn('CollectionPages:',
                           "Non-positive paginate value #{value.inspect} for collection '#{collection_name}' field '#{tag_field}'. " \
                           'Falling back to single page generation.')
        nil
      rescue ArgumentError, TypeError
        raise ArgumentError,
              "Invalid paginate value #{value.inspect} for collection '#{collection_name}' field '#{tag_field}'. Expected a numeric value."
      end
    end
  end

  class TagIndexPage < Page
    REQUIRED_KEYS = %i[dir page_number tag layout posts].freeze

    def initialize(site, attributes)
      validate_attributes!(attributes)
      @site = site
      @base = resolve_base(site, attributes[:layout])
      super(site, @base, '', attributes[:layout])

      @dir = attributes[:dir]
      @name = page_name(attributes[:page_number])

      process(@name)
      read_yaml(@base, attributes[:layout])
      assign_metadata(attributes)
    end

    private

    def validate_attributes!(attributes)
      missing = REQUIRED_KEYS.reject { |key| attributes.key?(key) }
      raise ArgumentError, "Missing TagIndexPage attributes: #{missing.join(', ')}" if missing.any?

      raise ArgumentError, 'page_number must be a positive integer' unless attributes[:page_number].to_i.positive?
      raise ArgumentError, 'layout must be a non-empty string' if attributes[:layout].to_s.empty?
      raise ArgumentError, 'dir must be a non-empty string' if attributes[:dir].to_s.empty?
      raise ArgumentError, 'posts must be an array-like object' unless attributes[:posts].respond_to?(:each)
    end

    def resolve_base(site, layout)
      site_layout = File.join(site.source, layout)
      return site.source if File.exist?(site_layout)

      theme_layout = site.theme && File.join(site.theme.root, layout)
      return site.theme.root if theme_layout && File.exist?(theme_layout)

      site.source
    end

    def page_name(page_number)
      page_number == 1 ? CollectionPages::INDEXFILE : "page#{page_number}.html"
    end

    def assign_metadata(attributes)
      data.merge!(
        'layout' => File.basename(attributes[:layout], '.*'),
        'tag' => attributes[:tag],
        'title' => attributes[:tag].to_s,
        'posts' => attributes[:posts]
      )
      assign_paginator(attributes[:paginator])
    end

    def assign_paginator(paginator)
      data['paginator'] = paginator if paginator
    end
  end

  class TagPager
    attr_reader :page, :per_page, :posts, :total_posts, :total_pages,
                :previous_page, :previous_page_path, :next_page, :next_page_path

    LIQUID_MAP = {
      'page' => :page,
      'per_page' => :per_page,
      'posts' => :posts,
      'total_posts' => :total_posts,
      'total_pages' => :total_pages,
      'previous_page' => :previous_page,
      'previous_page_path' => :previous_page_path,
      'next_page' => :next_page,
      'next_page_path' => :next_page_path
    }.freeze

    def self.calculate_pages(all_posts, per_page)
      per_page_value = per_page.to_i
      return 0 if per_page_value <= 0

      (all_posts.size.to_f / per_page_value).ceil
    end

    def initialize(page, per_page, all_posts)
      @page = page
      @per_page = per_page.to_i
      @total_posts = all_posts.size
      @total_pages = self.class.calculate_pages(all_posts, @per_page)
      @posts = slice_posts(all_posts)
    end

    def update_navigation(total_pages = @total_pages)
      @previous_page = previous_page_number
      @next_page = next_page_number(total_pages)
      @previous_page_path = page_path(@previous_page)
      @next_page_path = page_path(@next_page)
    end

    def to_liquid
      LIQUID_MAP.transform_values { |reader| public_send(reader) }
    end

    private

    def slice_posts(all_posts)
      return [] if @per_page <= 0

      start_index = (@page - 1) * @per_page
      all_posts.slice(start_index, @per_page) || []
    end

    def previous_page_number
      @page > 1 ? @page - 1 : nil
    end

    def next_page_number(total_pages)
      @page < total_pages ? @page + 1 : nil
    end

    def page_path(target_page)
      return unless target_page

      target_page == 1 ? CollectionPages::INDEXFILE : "page#{target_page}.html"
    end
  end
end
