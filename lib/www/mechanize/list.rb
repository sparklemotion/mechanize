module WWW
  class Mechanize
    # This class is deprecated and will be removed in Mechanize version 0.9.0
    class List < Array
      @@notified = false

      # This method provides syntax sugar so that you can write expressions
      # like this:
      #  form.fields.with.name('foo').and.href('bar.html')
      #
      def with
        if !@@notified
          $stderr.puts("WWW::Mechanize::List#with is deprecated and will be removed in Mechanize 0.9.0.")
          @@notified = true
        end
        self
      end

      def value=(arg)
        if !@@notified
          $stderr.puts("WWW::Mechanize::List#value= is deprecated and will be removed in Mechanize 0.9.0.")
          @@notified = true
        end
        first().value=(arg)
      end

      alias :and :with

      def respond_to?(method_sym)
        first.respond_to?(method_sym)
      end

      def method_missing(meth_sym, *args)
        if !@@notified
          $stderr.puts("WWW::Mechanize::List##{meth_sym} is deprecated and will be removed in version 0.9.0.  Please use: *_with(:#{meth_sym} => #{args.first ? args.first.inspect : 'nil'})")
          @@notified = true
        end
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
