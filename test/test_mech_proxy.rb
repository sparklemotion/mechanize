require "helper"

class TestMechProxy< Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_set_proxy
    @agent.set_proxy('www.example.com', 9001, 'joe', 'lol')

    assert_equal(@agent.proxy_addr, 'www.example.com')
    assert_equal(@agent.proxy_port, 9001)
    assert_equal(@agent.proxy_user, 'joe')
    assert_equal(@agent.proxy_pass, 'lol')
  end
end
