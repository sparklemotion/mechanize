module WWW
  class Mechanize
    class Page < WWW::Mechanize::File
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
          if (@text.nil? || @text.length == 0) && node.search('img').length > 0
            @text = ''
            node.search('img').each do |e|
              @text << ( e['alt'] || '')
            end
          end

        end

        def uri
          @href && URI.parse(@href)
        end

        # Click on this link
        def click
          @mech.click self
        end
      end
    end
  end
end
