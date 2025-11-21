# frozen_string_literal: true

require_relative 'collection_pages/collection_config'
require_relative 'collection_pages/collection_pager'
require_relative 'collection_pages/path_template'
require_relative 'collection_pages/tag_page'
require_relative 'collection_pages/tag_pager'
require_relative 'collection_pages/tag_path'
require_relative 'collection_pages/version'

module Jekyll
  module CollectionPages
    class CollectionPages < Generator
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
        else
          Jekyll.logger.error('CollectionPages:', 'Invalid configuration.')
        end
        Jekyll.logger.debug('CollectionPages:', "Generation complete. Total pages: #{site.pages.size}")
      end

      def generate_for_config(site, config)
        collection_config = CollectionConfig.new(config)
        Jekyll.logger.debug('CollectionPages:',
                            "Generating pages for collection: #{collection_config.collection_name}::#{collection_config.tag_field}")
        collection_pager = CollectionPager.new(site, collection_config)
        collection_pager.create_pages
      end
    end
  end
end
