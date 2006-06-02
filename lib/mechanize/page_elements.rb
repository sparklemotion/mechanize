module WWW
  class Link
    attr_reader :node
    attr_reader :href
    attr_reader :text
    alias :to_s :text
  
    def initialize(node)
      @node = node
      @href = node.attributes['href'] 
      @text = node.all_text

      # If there is no text, try to find an image and use it's alt text
      if (@text.nil? || @text.length == 0) && @node.has_elements?
        @text = ''
        @node.each_element { |e|
          if e.name == 'img'
            @text << (e.has_attributes? ? e.attributes['alt'] || '' : '')
          end
        }
      end
    end

    def uri
      URI.parse(@href)
    end

    def inspect
      "'#{@text}' -> #{@href}\n"
    end
  end
  
  class Meta < Link
  end

  class Frame
    attr_reader :node
    attr_reader :name
    attr_reader :src

    def initialize(node)
      @node = node
      @name = node.attributes['name']
      @src  = node.attributes['src']
    end

    def inspect
      "'#{@name}' -> #{@src}\n"
    end
  end
end
