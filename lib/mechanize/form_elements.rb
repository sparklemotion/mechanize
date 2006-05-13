module WWW
  class Field
    attr_accessor :name, :value
  
    def initialize(name, value)
      @name, @value = name, value
    end
  
    # Returns an array of Field objects
    # TODO: is this correct?
    def self.extract_all_from(root_node)
      fields = []
      root_node.each_recursive {|node|
        if (node.name.downcase == 'input' and 
           %w(text password hidden checkbox radio int).include?(node.attributes['type'].downcase)) or
           %w(textarea option).include?(node.name.downcase)
          fields << Field.new(node.attributes['name'], node.attributes['value']) 
        end
      }
      return fields
    end
  end
  
  class FileUpload
    # value is the file-name, not the file-content
    attr_accessor :name
    
    attr_accessor :file_name, :file_data, :mime_type
  
    def initialize(name, file_name)
      @name, @file_name = name, file_name
      @file_data = nil
    end
  end
  
  class Button
    attr_accessor :name, :value
  
    def initialize(name, value)
      @name, @value = name, value
    end
  
    def add_to_query(query)
      query[@name] = @value || "" if @name
    end
  
    # Returns an array of Button objects
    def self.extract_all_from(root_node)
      buttons = []
      root_node.each_recursive {|node|
        if node.name.downcase == 'input' and 
           ['submit'].include?(node.attributes['type'].downcase)
          buttons << Button.new(node.attributes['name'], node.attributes['value'])
        end
      }
      return buttons
    end
  end 
  
  class ImageButton < Button
    attr_accessor :x, :y
    
    def add_to_query(query)
      if @name
        query[@name] = @value || ""
        query[@name+".x"] = (@x || "0").to_s
        query[@name+".y"] = (@y || "0").to_s
      end
    end
  end
  
  class RadioButton
    attr_accessor :name, :value, :checked
  
    def initialize(name, value, checked)
      @name, @value, @checked = name, value, checked
    end
  end
  
  class CheckBox
    attr_accessor :name, :value, :checked
  
    def initialize(name, value, checked)
      @name, @value, @checked = name, value, checked
    end
  end
  
  class SelectList
    attr_accessor :name, :value, :options
  
    def initialize(name, node)
      @name = name
      @value = nil
      @options = []
  
      # parse
      node.each_recursive {|n|
        if n.name.downcase == 'option'
          option = Option.new(n)
          @options << option
          @value = option.value if option.selected
        end
      }
      @value = @options.first.value if @value == nil
    end
  end

  class Option
    attr_reader :value, :selected, :text

    alias :to_s :value

    def initialize(node)
      @text     = node.all_text
      @value    = node.attributes['value']
      @selected = node.attributes['selected'] ? true : false
    end
  end
end
