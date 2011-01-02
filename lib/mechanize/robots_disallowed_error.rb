class Mechanize
  class RobotsDisallowedError < RuntimeError
    attr_reader :uri
    def initialize(uri)
      @uri = uri
    end

    def to_s
      "Access disallowed by robots.txt: #{uri}"
    end
    alias :inspect :to_s
  end
end
