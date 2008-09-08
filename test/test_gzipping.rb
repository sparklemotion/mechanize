require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestGzip < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_request_empty_gzip
    assert_nothing_raised do
      page = @agent.get("http://localhost/gzip")
    end
  end

  def test_request_gzip
    page = nil
    assert_nothing_raised do
      page = @agent.get("http://localhost/gzip?file=index.html")
    end
    assert_kind_of(WWW::Mechanize::Page, page)
    assert_match('Hello World', page.body)
  end
end
