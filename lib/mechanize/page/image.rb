class Mechanize
  class Page < Mechanize::File
    class Image
      attr_reader :node
      attr_reader :page

      def initialize(node, page)
        @node = node
        @page = page
      end

      def src
        @node['src']
      end

      def url
        case src
        when %r{^https?://}
          src
        else
          (page.uri + src).to_s
        end
      end
    end
  end
end
