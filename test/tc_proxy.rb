require File.dirname(__FILE__) + "/helper"

Thread.new {
  require 'proxy'
}

class ProxyTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_proxy
    length = @agent.get("http://localhost/find_link.html").body.length
    @agent.set_proxy('127.0.0.1', PROXYPORT)
    l2 = @agent.get("http://localhost/find_link.html").body.length
    assert_equal(length, l2)
  end
end
