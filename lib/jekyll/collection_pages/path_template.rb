# frozen_string_literal: true

module Jekyll
  module CollectionPages
    INDEXFILE = 'index.html' unless const_defined?(:INDEXFILE)

    class PathTemplate
      attr_reader :tag_field, :collection_name

      def initialize(raw_template:, tag_field:, collection_name:, require_num: true)
        @tag_field = tag_field
        @collection_name = collection_name
        @require_num = require_num
        @template = build_effective_template(raw_template)
      end

      def template
        "/#{@template}"
      end

      private

      def build_effective_template(raw)
        sanitized = sanitize_path(raw)
        sanitized = default_placeholder if sanitized.empty?
        sanitized = add_field_placeholder(sanitized)
        sanitized = add_num_placeholder(sanitized) if @require_num
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

        "#{path}/#{INDEXFILE}"
      end

      def validate_template(path)
        field_count = path.scan(':field').size
        num_count = path.scan(':num').size

        error_msg = ''
        error_msg += "Path template '#{path}' must include exactly one ':field' placeholder. " if field_count != 1
        error_msg += "Path template '#{path}' must include exactly one ':num' placeholder. " if @require_num && num_count != 1

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
    end
  end
end
