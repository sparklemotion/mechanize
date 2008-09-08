module WWW
  class Mechanize
    class Form
      # This class contains option an option found within SelectList.  A
      # SelectList can have many Option classes associated with it.  An option
      # can be selected by calling Option#tick, or Option#click.  For example,
      # select the first option in a list:
      #  select_list.first.tick
      class Option
        attr_reader :value, :selected, :text, :select_list

        alias :to_s :value
        alias :selected? :selected

        def initialize(node, select_list)
          @text     = node.inner_text
          @value    = Util.html_unescape(node['value'] || node.inner_text)
          @selected = node.has_attribute? 'selected'
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
          if @select_list.instance_of? SelectList
            @select_list.select_none
          end
        end
      end
    end
  end
end
