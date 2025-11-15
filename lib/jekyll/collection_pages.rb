# frozen_string_literal: true

module Jekyll
  module CollectionPages
    INDEXFILE = 'index.html'

    class PathTemplate
      def initialize(raw_template:, tag_field:, collection_name:)
        @tag_field = tag_field
        @collection_name = collection_name
        @template = build_effective_template(raw_template)
      end

      def for_tag(tag_value)
        TagPathResolver.new(@template, tag_value)
      end

      def permalink
        TagPathResolver.new(@template, ':field', slugify_value: false).url_for(1)
      end

      def template
        "/#{@template}"
      end

      private

      def build_effective_template(raw)
        sanitized = sanitize_path(raw)
        sanitized = default_placeholder if sanitized.empty?
        sanitized = add_field_placeholder(sanitized)
        sanitized = add_num_placeholder(sanitized)
        sanitized = add_index(sanitized)
        Jekyll.logger.debug('CollectionPages:', "Using path template '#{sanitized}' for collection '#{@collection_name}'.")
        validate_template(sanitized)

        sanitized
      end

      def sanitize_path(path)
        path.to_s.strip.sub(%r{^/+}, '').sub(%r{/+\z}, '')
      end

      def default_placeholder
        @collection_name.to_s
      end

      def add_field_placeholder(path)
        return path if path.include?(':field')

        raise ArgumentError, "Path template '#{path}' must include a ':field' placeholder." if path.end_with?('.html') || path.end_with?('.htm')

        "#{path}/:field"
      end

      def add_num_placeholder(path)
        return path if path.include?(':num')

        raise ArgumentError, "Path template '#{path}' must include a ':num' placeholder." if path.end_with?('.html') || path.end_with?('.htm')

        "#{path}/page:num"
      end

      def add_index(path)
        return path if path.end_with?('.html') || path.end_with?('.htm')

        "#{path}/#{CollectionPages::INDEXFILE}"
      end

      def validate_template(path)
        field_count = path.scan(':field').size
        num_count = path.scan(':num').size

        error_msg = ''
        error_msg += "Path template '#{path}' must include exactly one ':field' placeholder. " if field_count != 1
        error_msg += "Path template '#{path}' must include exactly one ':num' placeholder. " if num_count != 1

        if num_count.positive? && field_count.positive?
          field_idx = path.index(':field')
          num_idx = path.index(':num')
          error_msg += "In path template '#{path}', ':field' must come before ':num'. " if num_idx < field_idx
        end

        segments = path.split('/').reject(&:empty?)
        segments.each do |segment|
          if segment.include?(':field') && segment.include?(':num')
            error_msg += "In path template '#{path}', ':field' and ':num' cannot be in the same file segment. "
          end
        end

        raise ArgumentError, error_msg unless error_msg.empty?
      end

      class TagPathResolver
        def initialize(template, field_value, slugify_value: true)
          @template = template
          @value = slugify_value ? Utils.slugify(field_value.to_s) : field_value.to_s
          @segments = template.split('/').reject(&:empty?)
        end

        def dir_for(page_number)
          segments = @segments
          segments = apply_field_value(segments)
          segments = page_number == 1 ? remove_paginated_segments(segments) : apply_page_number(segments, page_number)
          segments = drop_file_segment(segments)

          File.join(*segments)
        end

        def filename_for(page_number)
          return CollectionPages::INDEXFILE if page_number == 1

          segments = @segments.last(1)
          segments = apply_field_value(segments)
          segments = apply_page_number(segments, page_number)
          segments.join
        end

        def url_for(page_number)
          dir = dir_for(page_number)
          filename = filename_for(page_number)
          return formatted_index_path(dir) if filename == CollectionPages::INDEXFILE

          dir.empty? ? "/#{filename}" : "/#{dir}/#{filename}"
        end

        private

        def apply_field_value(segments)
          segments.map do |segment|
            segment.include?(':field') ? segment.gsub(':field', @value) : segment
          end
        end

        def apply_page_number(segments, page_number)
          segments.map do |segment|
            segment.include?(':num') ? segment.gsub(':num', page_number.to_s) : segment
          end
        end

        def drop_file_segment(segments)
          if segments.last.end_with?('.html') || segments.last.end_with?('.htm')
            segments[0...-1]
          else
            segments
          end
        end

        def remove_paginated_segments(segments)
          number_index = segments.index { |segment| segment.include?(':num') }
          number_index ? segments[0...number_index] : segments
        end

        def formatted_index_path(dir)
          return '/' if dir.empty?

          "/#{dir}/"
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
        Jekyll.logger.debug('CollectionPages:', "Generating pages for collection: #{collection_name}::#{tag_field}")

        path_template = PathTemplate.new(raw_template: tag_base_path, tag_field: tag_field, collection_name: collection_name)

        site.data['collection_pages'] ||= {}

        documents_map, metadata_map = generate_paginated_tags(site, path_template, tag_layout, collection_name, tag_field, per_page)

        collection_registry = site.data['collection_pages'][collection_name] ||= {}
        collection_registry[tag_field] = {
          'template' => path_template.template,
          'permalink' => path_template.permalink,
          'labels' => metadata_map,
          'pages' => documents_map
        }
      end

      def sorted_tags(site, collection_name, tag_field)
        tags = {}
        collection = site.collections[collection_name]
        return [] unless collection

        Jekyll.logger.debug('CollectionPages:', "Found collection '#{collection_name}' with #{collection.docs.size} entries.")
        collection.docs.each do |doc|
          doc_tags = doc.data[tag_field]
          next unless doc_tags

          doc_tags = [doc_tags] if doc_tags.is_a?(String)
          doc_tags.each do |tag|
            tags[tag] ||= []
            tags[tag] << doc
          end
        end
        tags.keys.sort.map { |tag| [tag, tags[tag]] }
      end

      def generate_paginated_tags(site, path_template, tag_layout, collection_name, tag_field, per_page)
        tags_with_docs = sorted_tags(site, collection_name, tag_field)

        documents_map = {}
        metadata_map = {}

        tags_with_docs.each do |tag, posts_with_tag|
          tag_path = path_template.for_tag(tag)

          page_count = TagPager.calculate_pages(posts_with_tag, per_page)
          tag_pages = []
          (1..page_count).each do |page_num|
            paginator = TagPager.new(page_num, per_page, posts_with_tag, tag_path) if per_page
            posts_for_page = paginator ? paginator.posts : posts_with_tag
            page_dir = tag_path.dir_for(page_num)
            page_filename = tag_path.filename_for(page_num)
            tag_page = build_page(site, page_dir, page_filename, tag, tag_layout, posts_for_page, page_num, paginator)
            site.pages << tag_page
            tag_pages << tag_page
          end

          documents_map[tag] = posts_with_tag
          metadata_map[tag] = {
            'pages' => tag_pages,
            'index' => tag_pages.first
          }
          Jekyll.logger.info('CollectionPages:',
                             "Generated #{tag_pages.size} page(s) for tag '#{tag}' in collection '#{collection_name}'.")
        end

        [documents_map, metadata_map]
      end

      def build_page(site, dir, page_filename, tag, layout, posts, page_num, paginator = nil)
        TagIndexPage.new(
          site,
          {
            dir: dir,
            name: page_filename,
            tag: tag,
            layout: layout,
            posts: posts,
            page_num: page_num,
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

  class TagIndexPage < PageWithoutAFile
    def initialize(site, attributes)
      dir = attributes[:dir]
      name = attributes[:name]
      tag = attributes[:tag]
      layout = attributes[:layout]
      posts = attributes[:posts]
      page_num = attributes[:page_num]
      paginator = attributes[:paginator]

      # This sets up a page that has no source file on disk.
      super(site, site.source, dir, name) # also calls process(name) internally

      self.content = '' # virtual page body (optional)

      self.data = {
        'layout' => File.basename(layout, '.*'), # layout NAME (no path)
        'tag' => tag,
        'title' => tag.to_s,
        'posts' => posts,
        'page_num' => page_num
      }
      data['paginator'] = paginator if paginator
    end
  end

  class TagPager
    attr_reader :page, :per_page, :posts, :total_posts, :total_pages,
                :previous_page, :previous_page_path, :next_page, :next_page_path

    LIQUID_MAP = {
      'page' => :page, # the current page number
      'per_page' => :per_page, # the number of posts per page
      'posts' => :posts, # the paginated posts for this page
      'total_posts' => :total_posts, # the total number of posts being paginated
      'total_pages' => :total_pages, # the total number of pages
      'previous_page' => :previous_page, # the previous page number, or nil
      'previous_page_path' => :previous_page_path, # the previous page path, or nil
      'next_page' => :next_page, # the next page number, or nil
      'next_page_path' => :next_page_path # the next page path, or nil
    }.freeze

    def self.calculate_pages(all_posts, per_page)
      per_page_value = per_page.to_i
      return 1 if per_page_value <= 0

      (all_posts.size.to_f / per_page_value).ceil
    end

    def initialize(page_num, per_page, all_posts, path_resolver)
      @page = page_num
      @per_page = per_page.to_i.positive? ? per_page.to_i : 0
      @total_posts = all_posts.size
      @total_pages = self.class.calculate_pages(all_posts, @per_page)
      @posts = slice_posts(all_posts)
      @path_resolver = path_resolver
      @previous_page = previous_page_number
      @next_page = next_page_number(total_pages)
      @previous_page_path = page_path(@previous_page)
      @next_page_path = page_path(@next_page)
    end

    def to_liquid
      LIQUID_MAP.transform_values { |reader| public_send(reader) }
    end

    private

    attr_reader :path_resolver

    def slice_posts(all_posts)
      return all_posts if @per_page <= 0

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
      return unless target_page && target_page <= total_pages

      path_resolver.url_for(target_page)
    end
  end
end
