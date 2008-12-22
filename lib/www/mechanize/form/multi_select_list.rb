module WWW
  class Mechanize
    class Form
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
          @options = []
      
          # parse
          node.search('option').each do |n|
            option = Option.new(n, self)
            @options << option
          end
          super(name, value)
        end

        def query_value
          value ? value.collect { |v| [name, v] } : ''
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
          [values].flatten.each do |value|
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
    end
  end
end
