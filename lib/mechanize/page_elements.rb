module WWW
  class Link
    attr_reader :node
    attr_reader :href
    attr_reader :text
  
    def initialize(node)
      @node = node
      @href = node.attributes['href'] 
      @text = node.all_text
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
  end
end
