class Mechanize::UnsupportedSchemeError < Mechanize::Error
  attr_accessor :scheme
  def initialize(scheme)
    @scheme = scheme
  end
end
