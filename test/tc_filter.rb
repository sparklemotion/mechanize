$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class FilterTest < Test::Unit::TestCase
  include TestMethods

  def test_local_filter
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/find_link.html")
    page.body_filter = lambda { |body| body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>') }
    assert_equal(16, page.links.length)
    assert_not_nil(page.links.text('Net::DAAP::Client').first)
    assert_equal(1, page.links.text('Net::DAAP::Client').length)
  end

  def test_global_filter
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    agent.body_filter = lambda { |body| body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>') }
    page = agent.get("http://localhost:#{@port}/find_link.html")
    assert_equal(16, page.links.length)
    assert_not_nil(page.links.text('Net::DAAP::Client').first)
    assert_equal(1, page.links.text('Net::DAAP::Client').length)

    page = agent.get("http://localhost:#{@port}/find_link.html")
    page.body_filter = lambda { |body| body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>') }
    assert_equal(17, page.links.length)
    assert_not_nil(page.links.text('Net::DAAP::Client').first)
    assert_equal(2, page.links.text('Net::DAAP::Client').length)
  end
end
