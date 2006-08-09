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

      def method_missing(meth_sym, *args)
        return first.send(meth_sym) if args.empty?
        arg = args.first
        if arg.class == Regexp
          WWW::Mechanize::List.new(find_all { |e| e.send(meth_sym) =~ arg })
        else
          WWW::Mechanize::List.new(find_all { |e| e.send(meth_sym) == arg })
        end
      end
    end
  end
end
