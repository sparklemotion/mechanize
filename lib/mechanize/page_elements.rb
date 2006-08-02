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
      alias :to_s :text
    
      def initialize(node)
        @node = node
        @href = node.attributes['href'] 
        @text = node.all_text
        @attributes = node.attributes

        # If there is no text, try to find an image and use it's alt text
        if (@text.nil? || @text.length == 0) && (node/'img').length > 0
          @text = ''
          (node/'img').each do |e|
            @text << (e.attributes.has_key?('alt') ? e.attributes['alt'] : '')
          end
        end

      end

      def uri
        URI.parse(@href)
      end

      def inspect
        "'#{@text}' -> #{@href}"
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

      def initialize(node)
        @node = node
        @text = node.attributes['name']
        @href = node.attributes['src']
      end
    end
  end
end
