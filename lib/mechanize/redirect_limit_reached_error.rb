class Mechanize
  # Thrown when too many redirects are sent
  class RedirectLimitReachedError < Mechanize::Error
    attr_reader :page, :response_code, :redirects
    def initialize(page, redirects)
      @page           = page
      @redirects      = redirects
      @response_code  = page.code
    end

    def to_s
      "Maximum redirect limit (#{redirects}) reached"
    end
    alias :inspect :to_s
  end
end
