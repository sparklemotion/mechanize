module WWW
  class Mechanize
    class UnsupportedSchemeError < RuntimeError
      attr_accessor :scheme
      def initialize(scheme)
        @scheme = scheme
      end
    end
  end
end
