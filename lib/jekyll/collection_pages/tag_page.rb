# frozen_string_literal: true

module Jekyll
  module CollectionPages
    class TagPage < PageWithoutAFile
      def initialize(site, attributes)
        dir = attributes[:dir]
        name = attributes[:name]
        tag = attributes[:tag]
        title = attributes[:title]
        layout = attributes[:layout]
        posts = attributes[:posts]
        page_num = attributes[:page_num]
        paginator = attributes[:paginator]

        # This sets up a page that has no source file on disk.
        super(site, site.source, dir, name) # also calls process(name) internally

        self.content = '' # virtual page body (optional)

        self.data = {
          'layout' => layout, # layout NAME (relative path, no _layouts prefix)
          'tag' => tag.to_s,
          'title' => title.to_s,
          'posts' => posts,
          'page_num' => page_num
        }
        data['paginator'] = paginator if paginator
      end
    end
  end
end
