require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestContentType < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_application_xhtml_xml
    url = 'http://localhost/content_type_test?ct=application/xhtml%2Bxml'
    page = @agent.get url
    assert_equal WWW::Mechanize::Page, page.class, "xhtml docs should return a Page"
  end
end
