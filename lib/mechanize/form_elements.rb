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
  
    def query_value
      [[@name, @value || '']]
    end

    def query_value
      [[@name, @value || '']]
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

    def query_value
        super <<
         [@name + ".x", (@x || 0).to_s] <<
         [@name + ".y", (@y || 0).to_s]
    end
  end
  
  # This class represents a radio button found in a Form.  To activate the
  # RadioButton in the Form, set the checked method to true.
  class RadioButton < Field
    attr_accessor :checked
  
    def initialize(name, value, checked, form)
      @checked = checked
      @form    = form
      super(name, value)
    end

    def tick
      uncheck_peers
      @checked = true
    end

    def untick
      @checked = false
    end

    def click
      @checked = !@checked
    end

    private
    def uncheck_peers
      @form.radiobuttons.name(name).each do |b|
        next if b.value == value
        b.untick
      end
    end
  end
  
  # This class represents a check box found in a Form.  To activate the
  # CheckBox in the Form, set the checked method to true.
  class CheckBox < RadioButton
    def query_value
      [[@name, @value || "on"]]
    end
  end
  
  # This class represents a select list where multiple values can be selected.
  # MultiSelectList#value= accepts an array, and those values are used as
  # values for the select list.  For example, to select multiple values,
  # simply do this:
  #  list.value = ['one', 'two']
  # Single values are still supported, so these two are the same:
  #  list.value = ['one']
  #  list.value = 'one'
  class MultiSelectList < Field
    attr_accessor :options
  
    def initialize(name, node)
      value = []
      @options = WWW::Mechanize::List.new
  
      # parse
      (node/'option').each do |n|
        option = Option.new(n, self)
        @options << option
      end
      super(name, value)
    end

    def query_value
      value.collect { |v| [name, v] }
    end

    # Select no options
    def select_none
      @value = []
      options.each { |o| o.untick }
    end

    # Select all options
    def select_all
      @value = []
      options.each { |o| o.tick }
    end

    # Get a list of all selected options
    def selected_options
      @options.find_all { |o| o.selected? }
    end

    def value=(values)
      select_none
      values.each do |value|
        option = options.find { |o| o.value == value }
        if option.nil?
          @value.push(value)
        else
          option.select
        end
      end
    end

    def value
      value = []
      value.push(*@value)
      value.push(*selected_options.collect { |o| o.value })
      value
    end
  end

  # This class represents a select list or drop down box in a Form.  Set the
  # value for the list by calling SelectList#value=.  SelectList contains a
  # list of Option that were found.  After finding the correct option, set
  # the select lists value to the option value:
  #  selectlist.value = selectlist.options.first.value
  # Options can also be selected by "clicking" or selecting them.  See Option
  class SelectList < MultiSelectList
    def initialize(name, node)
      super(name, node)
      if selected_options.length > 1
        selected_options.reverse[1..selected_options.length].each do |o|
          o.unselect
        end
      end
    end

    def value
      value = super
      if value.length > 0
        value.last
      elsif @options.length > 0
        @options.first.value
      else
        nil
      end
    end

    def value=(new)
      if new.respond_to? :first
        super([new.first])
      else
        super([new.to_s])
      end
    end
  end

  # This class contains option an option found within SelectList.  A
  # SelectList can have many Option classes associated with it.  An option
  # can be selected by calling Option#select, or Option#click.  For example,
  # select the first option in a list:
  #  select_list.first.select
  class Option
    attr_reader :value, :selected, :text, :select_list

    alias :to_s :value
    alias :selected? :selected

    def initialize(node, select_list)
      @text     = node.all_text
      @value    = node.attributes['value']
      @selected = node.attributes.has_key?('selected') ? true : false
      @select_list = select_list # The select list this option belongs to
    end

    # Select this option
    def select
      unselect_peers
      @selected = true
    end

    # Unselect this option
    def unselect
      @selected = false
    end

    alias :tick   :select
    alias :untick :unselect

    # Toggle the selection value of this option
    def click
      unselect_peers
      @selected = !@selected
    end

    private
    def unselect_peers
      if @select_list.instance_of? WWW::Mechanize::SelectList
        @select_list.select_none
      end
    end
  end
  end
end
