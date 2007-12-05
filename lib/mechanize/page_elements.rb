module WWW
  class Mechanize
    # This class encapsulates links.  It contains the text and the URI for
    # 'a' tags parsed out of an HTML page.  If the link contains an image,
    # the alt text will be used for that image.
    #
    # For example, the text for the following links with both be 'Hello World':
    #
    # <a href="http://rubyforge.org">Hello World</a>
    # <a href="http://rubyforge.org"><img src="test.jpg" alt="Hello World"></a>
    class Link
      attr_reader :node
      attr_reader :href
      attr_reader :text
      attr_reader :attributes
      attr_reader :page
      alias :to_s :text
      alias :referer :page
    
      def initialize(node, mech, page)
        @node = node
        @href = node['href'] 
        @text = node.inner_text
        @page = page
        @mech = mech
        @attributes = node

        # If there is no text, try to find an image and use it's alt text
        if (@text.nil? || @text.length == 0) && (node/'img').length > 0
          @text = ''
          (node/'img').each do |e|
            @text << ( e['alt'] || '')
          end
        end

      end

      def uri
        URI.parse(@href)
      end

      # Click on this link
      def click
        @mech.click self
      end
    end
    
    # This class encapsulates a Meta tag.  Mechanize treats meta tags just
    # like 'a' tags.  Meta objects will contain links, but most likely will
    # have no text.
    class Meta < Link
    end

    # This class encapsulates a 'frame' tag.  Frame objects can be treated
    # just like Link objects.  They contain src, the link they refer to,
    # name, the name of the frame.  'src' and 'name' are aliased to 'href'
    # and 'text' respectively so that a Frame object can be treated just
    # like a Link.
    class Frame < Link
      alias :src :href
      alias :name :text

      def initialize(node, mech, referer)
        super(node, mech, referer)
        @node = node
        @text = node['name']
        @href = node['src']
      end
    end

    # This class encapsulates a Base tag.  Mechanize treats base tags just like
    # 'a' tags.  Base objects will contain links, but most likely will have
    # no text.
    class Base < Link
    end
  end
end
