class Mechanize::UnsupportedSchemeError < Mechanize::Error
  attr_accessor :scheme, :link

  def initialize(scheme, link)
    @scheme = scheme
    @link   = link
  end
end
