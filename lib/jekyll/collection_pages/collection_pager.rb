# frozen_string_literal: true

module Jekyll
  module CollectionPages
    class CollectionPager
      def initialize(site, config)
        @site = site
        @config = config
        @tags_with_docs = sorted_tags(site, config.collection_name, config.tag_field)
        path_template = PathTemplate.new(raw_template: config.tag_base_path, tag_field: config.tag_field, collection_name: config.collection_name,
                                         require_num: !config.per_page.nil? && config.per_page.positive?)
        @template = path_template.template
        @permalink = TagPath.new(@template, ':field', slugify_value: false).url_for(1)
      end

      def create_pages
        documents_map = {}
        metadata_map = {}
        @tags_with_docs.each do |tag, posts_with_tag|
          page_count = TagPager.calculate_pages(posts_with_tag, @config.per_page)
          tag_pages = []
          (1..page_count).each do |page_num|
            tag_page = build_page(@site, tag, posts_with_tag, page_num)
            @site.pages << tag_page
            tag_pages << tag_page
          end
          documents_map[tag] = posts_with_tag
          metadata_map[tag] = {
            'pages' => tag_pages,
            'index' => tag_pages.first
          }
          Jekyll.logger.info('CollectionPages:',
                             "Generated #{tag_pages.size} page(s) for tag '#{tag}' in collection '#{@config.collection_name}'.")
        end

        set_metadata(documents_map, metadata_map)
      end

      private

      def set_metadata(documents_map, metadata_map)
        @site.data['collection_pages'] ||= {}
        collection_registry = @site.data['collection_pages'][@config.collection_name] ||= {}
        collection_registry[@config.tag_field] = {
          'template' => @template,
          'permalink' => @permalink,
          'labels' => metadata_map,
          'pages' => documents_map
        }
      end

      def build_page(site, tag, posts_with_tag, page_num)
        tag_path = TagPath.new(@template, tag)
        paginator = TagPager.new(page_num, @config.per_page, posts_with_tag)

        paginator_liquid = paginator.to_liquid.merge(
          'previous_page_path' => tag_path.url_for(paginator.previous_page),
          'next_page_path' => tag_path.url_for(paginator.next_page)
        )
        TagPage.new(
          site,
          {
            dir: tag_path.dir_for(page_num),
            name: tag_path.filename_for(page_num),
            title: tag,
            tag: tag_path.tag,
            layout: @config.tag_layout,
            posts: paginator.posts,
            page_num: page_num,
            paginator: @config.per_page ? paginator_liquid : nil
          }
        )
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
    end
  end
end
