require "helper"

class TestContentType < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_application_xhtml_xml
    url = 'http://localhost/content_type_test?ct=application/xhtml%2Bxml'
    page = @agent.get url
    assert_equal Mechanize::Page, page.class, "xhtml docs should return a Page"
  end
end
