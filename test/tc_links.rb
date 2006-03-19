$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'

class LinksMechTest < Test::Unit::TestCase
  def setup
    @port = 2000
  end

  def test_find_meta
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/find_link.html")
    assert_equal(2, page.meta.length)
    assert_equal("http://www.drphil.com/", page.meta[0].href.downcase)
    assert_equal("http://www.upcase.com/", page.meta[1].href.downcase)
  end

  def test_find_link
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/find_link.html")
    assert_equal(15, page.links.length)
  end
end
