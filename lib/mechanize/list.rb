module WWW
  class Mechanize
    class List < Array
      def with
        self
      end

      def value=(arg)
        first().value=(arg)
      end

      alias :and :with

      def method_missing(meth_sym, arg)
        if arg.class == Regexp
          WWW::Mechanize::List.new(find_all { |e| e.send(meth_sym) =~ arg })
        else
          WWW::Mechanize::List.new(find_all { |e| e.send(meth_sym) == arg })
        end
      end
    end
  end
end
