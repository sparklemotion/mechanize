$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestGzip < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_request_gzip
    page = nil
    assert_nothing_raised do
      page = @agent.get("http://localhost:#{PORT}/gzip?file=index.html")
    end
    assert_kind_of(WWW::Mechanize::Page, page)
    assert_match('Hello World', page.body)
  end
end
