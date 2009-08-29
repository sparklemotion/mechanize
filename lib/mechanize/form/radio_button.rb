class Mechanize
  class Form
    # This class represents a radio button found in a Form.  To activate the
    # RadioButton in the Form, set the checked method to true.
    class RadioButton < Field
      attr_accessor :checked

      def initialize(name, value, checked, form, node)
        @checked = checked
        @form    = form
        @node    = node
        super(name, value)
      end

      def check
        uncheck_peers
        @checked = true
      end

      def uncheck
        @checked = false
      end

      def click
        checked ? uncheck : check
      end

      def label
        (id = @node['id']) && @form.page.labels_hash[id] || nil
      end

      def text
        label.text rescue nil
      end

      private
      def uncheck_peers
        @form.radiobuttons_with(:name => name).each do |b|
          next if b.value == value
          b.uncheck
        end
      end
    end
  end
end
