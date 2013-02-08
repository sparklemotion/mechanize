class Mechanize::XmlFile < Mechanize::File
  extend Forwardable

  attr_reader :xml

  def initialize(uri = nil, response = nil, body = nil, code = nil)
    super uri, response, body, code
    @xml = Nokogiri.XML body
  end

  def_delegator :xml, :search, :search
  def_delegator :xml, :at, :at
end