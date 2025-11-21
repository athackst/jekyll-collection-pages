# frozen_string_literal: true

module Jekyll
  module CollectionPages
    class TagPager
      attr_reader :page, :per_page, :posts, :total_posts, :total_pages,
                  :previous_page, :next_page

      LIQUID_MAP = {
        'page' => :page, # the current page number
        'per_page' => :per_page, # the number of posts per page
        'posts' => :posts, # the paginated posts for this page
        'total_posts' => :total_posts, # the total number of posts being paginated
        'total_pages' => :total_pages, # the total number of pages
        'previous_page' => :previous_page, # the previous page number, or nil
        'next_page' => :next_page # the next page number, or nil
      }.freeze

      def self.calculate_pages(all_posts, per_page)
        per_page_value = per_page.to_i
        return 1 if per_page_value <= 0

        (all_posts.size.to_f / per_page_value).ceil
      end

      def initialize(page_num, per_page, all_posts)
        @page = page_num
        @per_page = per_page.to_i.positive? ? per_page.to_i : 0
        @total_posts = all_posts.size
        @total_pages = self.class.calculate_pages(all_posts, @per_page)
        @posts = slice_posts(all_posts)
        @previous_page = previous_page_number
        @next_page = next_page_number(total_pages)
      end

      def to_liquid
        LIQUID_MAP.transform_values { |reader| public_send(reader) }
      end

      private

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
    end
  end
end
