$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class PageTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
  end

  def test_title
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    assert_equal('File Upload Form', page.title)
  end

  def test_no_title
    page = @agent.get("http://localhost:#{PORT}/no_title_test.html")
    assert_equal(nil, page.title)
  end
end
