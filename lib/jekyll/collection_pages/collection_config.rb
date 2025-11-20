# frozen_string_literal: true

module Jekyll
  module CollectionPages
    class CollectionConfig
      attr_reader :collection_name, :tag_field, :tag_base_path, :tag_layout, :per_page

      def initialize(config)
        unless config.is_a?(Hash)
          Jekyll.logger.error('CollectionPages:', "Invalid collection config entry: #{config.inspect}.")
          raise ArgumentError, "Invalid collection_pages config entry. #{config.inspect}."
        end
        @collection_name = config['collection']
        @tag_field = config['field']
        @tag_base_path = config['path'] || @collection_name
        @tag_layout = normalize_layout(config['layout'] || 'collection_layout')
        @per_page = normalize_paginate_value(config['paginate'])

        validate_config
      end

      private

      def validate_config
        missing_keys = []
        missing_keys << 'collection' unless @collection_name
        missing_keys << 'field' unless @tag_field
        return if missing_keys.empty?

        Jekyll.logger.error('CollectionPages:', "Missing required config keys: #{missing_keys.join(', ')}.")
        raise ArgumentError, "Invalid collection_pages config entry. Missing: #{missing_keys.join(', ')}."
      end

      def normalize_paginate_value(value)
        return nil if value.nil?

        per_page = Integer(value)
        return per_page if per_page.positive?

        Jekyll.logger.warn('CollectionPages:',
                           "Non-positive paginate value #{value.inspect} for collection '#{@collection_name}' field '#{@tag_field}'. " \
                           'Falling back to single page generation.')
        nil
      rescue ArgumentError, TypeError
        raise ArgumentError,
              "Invalid paginate value #{value.inspect} for collection '#{@collection_name}' field '#{@tag_field}'. Expected a numeric value."
      end

      def normalize_layout(layout)
        layout.to_s.sub(/\.[^.]+\z/, '').sub(%r{\A_layouts/}, '')
      end
    end
  end
end
