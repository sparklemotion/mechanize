module WWW
  class Mechanize
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
  
    def inspect
      "#{name} = #{@value}"
    end
  end
  
  # This class represents a file upload field found in a form.  To use this
  # class, set WWW::FileUpload#file_data= to the data of the file you want
  # to upload and WWW::FileUpload#mime_type= to the appropriate mime type
  # of the file.
  # See the example in EXAMPLES[link://files/EXAMPLES.html]
  class FileUpload < Field
    attr_accessor :name # Field name
    attr_accessor :file_name # File name
    attr_accessor :mime_type # Mime Type (Optional)
    
    alias :file_data :value
    alias :file_data= :value=
  
    def initialize(name, file_name)
      @file_name = file_name
      @file_data = nil
      super(name, @file_data)
    end
  end
  
  # This class represents a Submit button in a form.
  class Button < Field
    def add_to_query(query)
      query << [@name, @value || ''] if @name
    end
  end 
  
  # This class represents an image button in a form.  Use the x and y methods
  # to set the x and y positions for where the mouse "clicked".
  class ImageButton < Button
    attr_accessor :x, :y
    
    def initialize(name, value)
      @x = nil
      @y = nil
      super(name, value)
    end

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
  class RadioButton < Field
    attr_accessor :checked
  
    def initialize(name, value, checked)
      @checked = checked
      super(name, value)
    end
  end
  
  # This class represents a check box found in a Form.  To activate the
  # CheckBox in the Form, set the checked method to true.
  class CheckBox < RadioButton
  end
  
  # This class represents a select list or drop down box in a Form.  Set the
  # value for the list by calling SelectList#value=.  SelectList contains a
  # list of Option that were found.  After finding the correct option, set
  # the select lists value to the option value:
  #  selectlist.value = selectlist.options.first.value
  class SelectList < Field
    attr_accessor :options
  
    def initialize(name, node)
      value = nil
      @options = WWW::Mechanize::List.new
  
      # parse
      (node/'option').each do |n|
        option = Option.new(n)
        @options << option
        value = option.value if option.selected && value.nil?
      end
      value = @options.first.value if (value == nil && @options.first)
      super(name, value)
    end

    alias :old_value= :value=

    def value=(value)
      @value = value.to_s
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
end
