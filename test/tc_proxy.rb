$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

Thread.new {
  require 'proxy'
}

class ProxyTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_proxy
    length = @agent.get("http://localhost:#{PORT}/find_link.html").body.length
    @agent.set_proxy('127.0.0.1', PROXYPORT)
    l2 = @agent.get("http://localhost:#{PORT}/find_link.html").body.length
    assert_equal(length, l2)
  end
end
