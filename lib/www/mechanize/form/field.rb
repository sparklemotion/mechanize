module WWW
  class Mechanize
    class Form
      # This class represents a field in a form.  It handles the following input
      # tags found in a form:
      # text, password, hidden, int, textarea
      #
      # To set the value of a field, just use the value method:
      # field.value = "foo"
      class Field
        attr_accessor :name, :value
      
        def initialize(name, value)
          @name = Util.html_unescape(name)
          @value = if value.is_a? String
                     Util.html_unescape(value)
                   else
                     value
                   end
        end
      
        def query_value
          [[@name, @value || '']]
        end
      end
    end
  end
end
