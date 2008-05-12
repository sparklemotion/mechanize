require File.dirname(__FILE__) + "/helper"

class BasicAuthTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_auth_success
    @agent.basic_auth('user', 'pass')
    page = @agent.get("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
  end

  def test_post_auth_success
    class << @agent
      alias :old_fetch_request :fetch_request
      attr_accessor :requests
      def fetch_request(*args)
        @requests ||= []
        @requests << old_fetch_request(*args)
        @requests.last
      end
    end
    @agent.basic_auth('user', 'pass')
    page = @agent.post("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
    assert_equal(2, @agent.requests.length)
    r1 = @agent.requests[0]
    r2 = @agent.requests[1]
    assert r1['Content-Type']
    assert r2['Content-Type']
    assert_equal(r1['Content-Type'], r2['Content-Type'])

    assert r1['Content-Length']
    assert r2['Content-Length']
    assert_equal(r1['Content-Length'], r2['Content-Length'])
  end

  def test_auth_bad_user_pass
    @agent.basic_auth('aaron', 'aaron')
    begin
      page = @agent.get("http://localhost/basic_auth")
    rescue WWW::Mechanize::ResponseCodeError => e
      assert_equal("401", e.response_code)
    end
  end

  def test_auth_failure
    begin
      page = @agent.get("http://localhost/basic_auth")
    rescue WWW::Mechanize::ResponseCodeError => e
      assert_equal("401", e.response_code)
    end
  end

end
