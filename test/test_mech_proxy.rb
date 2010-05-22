require "helper"

class TestMechProxy< Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_set_proxy
    @agent.set_proxy('www.example.com', 9001, 'joe', 'lol')

    assert_equal(@agent.http.proxy_uri.host,     'www.example.com')
    assert_equal(@agent.http.proxy_uri.port,     9001)
    assert_equal(@agent.http.proxy_uri.user,     'joe')
    assert_equal(@agent.http.proxy_uri.password, 'lol')
  end
end
