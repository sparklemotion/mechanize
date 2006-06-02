module WWW
  # This class represents a field in a form.  It handles the following input
  # tags found in a form:
  # text, password, hidden, int, textarea
  #
  # To set the value of a field, just use the value method:
  # field.value = "foo"
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

    def inspect
      "#{name} = #{@value}\n"
    end
  end
  
  # This class represents a file upload field found in a form.  To use this
  # class, set WWW::FileUpload#file_data= to the data of the file you want
  # to upload and WWW::FileUpload#mime_type= to the appropriate mime type
  # of the file.
  # See the example in EXAMPLES[link://files/EXAMPLES.html]
  class FileUpload
    # value is the file-name, not the file-content
    attr_accessor :name
    
    attr_accessor :file_name, :file_data, :mime_type
  
    def initialize(name, file_name)
      @name, @file_name = name, file_name
      @file_data = nil
    end
  end
  
  # This class represents a Submit button in a form.
  class Button
    attr_accessor :name, :value
  
    def initialize(name, value)
      @name, @value = name, value
    end
  
    def add_to_query(query)
      query << [@name, @value || ''] if @name
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

    def inspect
      "#{name} = #{@value}\n"
    end
  end 
  
  # This class represents an image button in a form.  Use the x and y methods
  # to set the x and y positions for where the mouse "clicked".
  class ImageButton < Button
    attr_accessor :x, :y
    
    def add_to_query(query)
      if @name
        query << [@name, @value || '']
        query << [@name + ".x", (@x || 0).to_s]
        query << [@name + ".y", (@y || 0).to_s]
      end
    end
  end
  
  # This class represents a radio button found in a Form.  To activate the
  # RadioButton in the Form, set the checked method to true.
  class RadioButton
    attr_accessor :name, :value, :checked
  
    def initialize(name, value, checked)
      @name, @value, @checked = name, value, checked
    end

    def inspect
      "#{name} = #{@value}\n"
    end
  end
  
  # This class represents a check box found in a Form.  To activate the
  # CheckBox in the Form, set the checked method to true.
  class CheckBox
    attr_accessor :name, :value, :checked
  
    def initialize(name, value, checked)
      @name, @value, @checked = name, value, checked
    end

    def inspect
      "#{name} = #{@value}\n"
    end
  end
  
  # This class represents a select list or drop down box in a Form.  Set the
  # value for the list by calling SelectList#value=.  SelectList contains a
  # list of Option that were found.  After finding the correct option, set
  # the select lists value to the option value:
  #  selectlist.value = selectlist.options.first.value
  class SelectList
    attr_accessor :name, :options
    attr_reader :value
  
    def initialize(name, node)
      @name = name
      @value = nil
      @options = WWW::Mechanize::List.new
  
      # parse
      node.each_recursive {|n|
        if n.name.downcase == 'option'
          option = Option.new(n)
          @options << option
          @value = option.value if option.selected
        end
      }
      @value = @options.first.value if (@value == nil && @options.first)
    end

    def value=(value)
      @value = value.to_s
    end

    def inspect
      "#{name} = #{@value}\n"
    end
  end

  # This class contains option an option found within SelectList.  A
  # SelectList can have many Option classes associated with it.
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
