module WWW
  class Mechanize
    # = Synopsis
    # This class provides syntax sugar to help find things within Mechanize.
    # Most calls in Mechanize that return arrays, like the 'links' method
    # WWW::Mechanize::Page return a Mechanize::List.  This class lets you
    # find things with a particular attribute on the found class.
    #
    # If you have an array with objects that response to the method "name",
    # and you want to find all objects where name equals 'foo', your code
    # would look like this:
    #
    #  list.name('foo') # => Mechanize::List
    #
    # == A bit more information
    # Mechanize::List will iterate through all of the objects it contains,
    # testing to see if the object will respond to the "name" method.  If it
    # does, it will test to see if calling the name method returns a value
    # equal to the value passed in.
    #
    # Finding the list will return another list, so it is possible to chain
    # calls with Mechanize::List.  For example:
    #
    #  list.name('foo').href('bar.html')
    #
    # This code will find all elements with name 'foo' and href 'bar.html'.
    # If you call a method with no arguments that List does not know how to
    # respond to, it will try that method on the first element of the array.
    # This lets you treat the array like the type of object it contains.
    # For example, you can click the first element in the array just by
    # saying:
    #  agent.click page.links
    # Or click the first link with the text "foo"
    #  agent.click page.links.text('foo')
    class List < Array
      # This method provides syntax sugar so that you can write expressions
      # like this:
      #  form.fields.with.name('foo').and.href('bar.html')
      #
      def with
        self
      end

      # This method will allow the you to set the value of the first element
      # in the list.  For example, finding an input field with name 'foo'
      # and setting the value to 'bar'.
      #
      #  form.fields.name('foo').value = 'bar'
      #
      def value=(arg)
        first().value=(arg)
      end

      alias :and :with

      def respond_to?(method_sym)
        first.respond_to?(method_sym)
      end

      def method_missing(meth_sym, *args)
        if length > 0
          return first.send(meth_sym) if args.empty?
          arg = args.first
          if arg.class == Regexp
            WWW::Mechanize::List.new(find_all { |e| e.send(meth_sym) =~ arg })
          else
            WWW::Mechanize::List.new(find_all { |e| e.send(meth_sym) == arg })
          end
        else
          ''
        end
      end
    end
  end
end
