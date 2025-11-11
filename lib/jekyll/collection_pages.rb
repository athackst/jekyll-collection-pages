# frozen_string_literal: true

module Jekyll
  module CollectionPages
    INDEXFILE = 'index.html'

    class PathTemplate
      def initialize(raw_template, tag_field)
        @raw_template = raw_template
        @tag_field = tag_field
        @template = build_effective_template(raw_template)
      end

      def for_tag(tag_value)
        TagPath.new(@template, tag_value)
      end

      def permalink
        TagPath.new(@template, ":#{@tag_field}", slugify_value: false).dir_for(1)
      end

      private

      def build_effective_template(raw_template)
        sanitized = sanitize_path(raw_template)
        sanitized = default_placeholder if sanitized.empty?
        return sanitized if contains_field_placeholder?(sanitized)

        [sanitized, ':slug'].reject(&:empty?).join('/')
      end

      def sanitize_path(path)
        path.to_s.strip.sub(%r{^/+}, '').sub(%r{/+\z}, '')
      end

      def contains_field_placeholder?(path)
        path.include?(':slug') || path.include?(':field')
      end

      def default_placeholder
        ':slug'
      end

      class TagPath
        def initialize(template, value, slugify_value: true)
          @template = template
          @value = slugify_value ? Utils.slugify(value.to_s) : value.to_s
        end

        def dir_for(page_number)
          segments = apply_value
          segments = apply_page_number(segments, page_number)
          join_segments(segments)
        end

        def filename_for(page_number)
          return CollectionPages::INDEXFILE if page_number == 1

          uses_page_directories? ? CollectionPages::INDEXFILE : "page#{page_number}.html"
        end

        def url_for(page_number)
          dir = dir_for(page_number)
          filename = filename_for(page_number)
          return formatted_index_path(dir) if filename == CollectionPages::INDEXFILE

          dir.empty? ? filename : File.join(dir, filename)
        end

        def uses_page_directories?
          @template.include?(':num')
        end

        private

        def apply_value
          segments = split_template
          segments.map { |segment| segment.gsub(':slug', @value).gsub(':field', @value) }
        end

        def split_template
          @template.split('/').reject(&:empty?)
        end

        def apply_page_number(segments, page_number)
          return remove_paginated_segments(segments) if page_number.nil? || page_number <= 1 || !uses_page_directories?

          segments.map do |segment|
            segment.include?(':num') ? segment.gsub(':num', page_number.to_s) : segment
          end
        end

        def remove_paginated_segments(segments)
          uses_page_directories? ? segments.reject { |segment| segment.include?(':num') } : segments
        end

        def join_segments(segments)
          segments.join('/')
        end

        def formatted_index_path(dir)
          return '' if dir.empty?

          dir.end_with?('/') ? dir : "#{dir}/"
        end
      end
    end

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
        path_template = PathTemplate.new(tag_base_path, tag_field)

        site.data['collection_pages'] ||= {}

        Jekyll.logger.debug('CollectionPages:', "Generating pages for collection: #{collection_name}")
        documents_map, metadata_map = if per_page
                                        generate_paginated_tags(site, path_template, tag_layout_path, collection_name, tag_field, per_page)
                                      else
                                        generate_tags(site, path_template, tag_layout_path, collection_name, tag_field)
                                      end

        collection_registry = site.data['collection_pages'][collection_name] ||= {}
        collection_registry[tag_field] = {
          'field' => tag_field,
          'path' => tag_base_path,
          'permalink' => path_template.permalink,
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

      def generate_paginated_tags(site, path_template, tag_layout, collection_name, tag_field, per_page)
        tags = sorted_tags(site, collection_name, tag_field)

        documents_map = {}
        metadata_map = {}

        tags.each do |tag|
          tag_path = path_template.for_tag(tag)
          posts_with_tag = site.collections[collection_name].docs.select do |doc|
            doc_tags = doc.data[tag_field]
            doc_tags && (doc_tags.is_a?(String) ? doc_tags == tag : doc_tags.include?(tag))
          end

          page_count = TagPager.calculate_pages(posts_with_tag, per_page)
          tag_pages = []
          (1..page_count).each do |page_num|
            paginator = TagPager.new(page_num, per_page, posts_with_tag, path_resolver: tag_path)
            paginator.update_navigation(page_count)
            page_dir = tag_path.dir_for(page_num)
            page_filename = tag_path.filename_for(page_num)
            tag_page = build_page(site, page_dir, page_num, tag, tag_layout, paginator.posts, paginator, page_filename: page_filename)
            site.pages << tag_page
            tag_pages << tag_page
          end

          documents_map[tag] = posts_with_tag
          metadata_map[tag] = {
            'pages' => tag_pages,
            'page' => tag_pages.first,
            'path' => tag_path.dir_for(1),
            'layout' => File.basename(tag_layout, '.*'),
            'paginate' => per_page
          }
        end

        Jekyll.logger.info('CollectionPages:',
                           "Generated #{tags.size} paginated index pages for collection '#{collection_name}' with field '#{tag_field}'")
        Jekyll.logger.debug('CollectionPages:', "Pages made for: #{tags.inspect}")

        [documents_map, metadata_map]
      end

      def generate_tags(site, path_template, tag_layout, collection_name, tag_field)
        tags = sorted_tags(site, collection_name, tag_field)

        documents_map = {}
        metadata_map = {}

        tags.each do |tag|
          tag_path = path_template.for_tag(tag)
          posts_with_tag = site.collections[collection_name].docs.select do |doc|
            doc_tags = doc.data[tag_field]
            doc_tags && (doc_tags.is_a?(String) ? doc_tags == tag : doc_tags.include?(tag))
          end
          page_dir = tag_path.dir_for(1)
          page_filename = tag_path.filename_for(1)
          tag_page = build_page(site, page_dir, 1, tag, tag_layout, posts_with_tag, nil, page_filename: page_filename)
          site.pages << tag_page
          documents_map[tag] = posts_with_tag
          metadata_map[tag] = {
            'pages' => [tag_page],
            'page' => tag_page,
            'path' => page_dir,
            'layout' => File.basename(tag_layout, '.*'),
            'paginate' => nil
          }
        end

        Jekyll.logger.info('CollectionPages:', "Generated #{tags.size} index pages for collection '#{collection_name}'")
        Jekyll.logger.debug('CollectionPages:', "Pages made for: #{tags.inspect}")

        [documents_map, metadata_map]
      end

      def build_page(site, dir, page_number, tag, layout, posts, paginator = nil, page_filename: nil)
        TagIndexPage.new(
          site,
          {
            dir: dir,
            page_number: page_number,
            tag: tag,
            layout: layout,
            posts: posts,
            paginator: paginator,
            page_filename: page_filename
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
      @name = attributes[:page_filename] || page_name(attributes[:page_number])

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

      return unless attributes[:page_filename]
      raise ArgumentError, 'page_filename must be a non-empty string' if attributes[:page_filename].to_s.empty?
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

    def initialize(page, per_page, all_posts, base_path: nil, path_resolver: nil)
      @page = page
      @per_page = per_page.to_i
      @total_posts = all_posts.size
      @total_pages = self.class.calculate_pages(all_posts, @per_page)
      @posts = slice_posts(all_posts)
      @base_path = normalize_base_path(base_path)
      @path_resolver = path_resolver
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

    attr_reader :base_path, :path_resolver

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

      return path_resolver.url_for(target_page) if path_resolver

      filename = target_page == 1 ? CollectionPages::INDEXFILE : "page#{target_page}.html"
      return filename unless base_path

      if target_page == 1
        File.join(base_path, '')
      else
        File.join(base_path, filename)
      end
    end

    def normalize_base_path(path)
      return nil if path.nil?

      trimmed = path.to_s.strip
      trimmed.empty? ? nil : trimmed
    end
  end
end
