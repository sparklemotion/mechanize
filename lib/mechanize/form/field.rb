class Mechanize
  class Form
    # This class represents a field in a form.  It handles the following input
    # tags found in a form:
    # text, password, hidden, int, textarea, keygen
    #
    # To set the value of a field, just use the value method:
    # field.value = "foo"
    class Field
      attr_accessor :name, :value, :node

      def initialize node, value = node['value']
        @node = node
        @name = Util.html_unescape(node['name'])
        @value = if value.is_a? String
                   Util.html_unescape(value)
                 else
                   value
                 end
      end

      def query_value
        [[@name, @value || '']]
      end

      def <=> other
        return 0 if self == other
        return 1 if Hash === node
        return -1 if Hash === other.node
        node <=> other.node
      end

      # This method is a shortcut to get field's DOM id.
      # Common usage: form.field_with(:dom_id => "foo")
      def dom_id
        node['id']
      end
    end

    class Text     < Field; end
    class Textarea < Field; end
    class Hidden   < Field; end
  end
end
