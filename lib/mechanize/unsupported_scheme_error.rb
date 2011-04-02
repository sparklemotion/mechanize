class Mechanize
  class UnsupportedSchemeError < Mechanize::Error
    attr_accessor :scheme
    def initialize(scheme)
      @scheme = scheme
    end
  end
end
