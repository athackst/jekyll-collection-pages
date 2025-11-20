# frozen_string_literal: true

module Jekyll
  module CollectionPages
    class TagPath
      attr_reader :tag

      def initialize(template, field_value, slugify_value: true)
        @template = template
        @tag = slugify_value ? Utils.slugify(field_value.to_s) : field_value.to_s
        @segments = template.split('/').reject(&:empty?)
        @explicit_file = file_segment?(@segments.last) && @segments.last.include?(':field')
      end

      def dir_for(page_number)
        segments = @segments
        segments = apply_field_value(segments)
        segments = page_number == 1 ? remove_paginated_segments(segments) : apply_page_number(segments, page_number)
        segments = drop_file_segment(segments)

        File.join(*segments)
      end

      def filename_for(page_number)
        segments = @segments.last(1)
        segments = apply_field_value(segments)

        if page_number == 1
          return segments.join if @explicit_file

          return INDEXFILE
        end

        segments = apply_page_number(segments, page_number)
        segments.join
      end

      def url_for(page_number)
        return nil if page_number.nil?

        dir = dir_for(page_number)
        filename = filename_for(page_number)
        return formatted_index_path(dir) if filename == INDEXFILE

        dir.empty? ? "/#{filename}" : "/#{dir}/#{filename}"
      end

      private

      def apply_field_value(segments)
        segments.map do |segment|
          segment.include?(':field') ? segment.gsub(':field', @tag) : segment
        end
      end

      def apply_page_number(segments, page_number)
        segments.map do |segment|
          segment.include?(':num') ? segment.gsub(':num', page_number.to_s) : segment
        end
      end

      def drop_file_segment(segments)
        if file_segment?(segments.last)
          segments[0...-1]
        else
          segments
        end
      end

      def file_segment?(segment)
        segment && (segment.end_with?('.html') || segment.end_with?('.htm'))
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
end
