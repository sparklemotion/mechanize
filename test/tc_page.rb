require File.dirname(__FILE__) + "/helper"

class TestPage < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_title
    page = @agent.get("http://localhost/file_upload.html")
    assert_equal('File Upload Form', page.title)
  end

  def test_no_title
    page = @agent.get("http://localhost/no_title_test.html")
    assert_equal(nil, page.title)
  end
end
