require File.expand_path(File.join(File.dirname(__FILE__), "helper"))
require 'pp'

class BasicAuthTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_auth_success
    @agent.basic_auth('user', 'pass')
    page = @agent.get("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
  end

  def test_digest_auth_success
    @agent.basic_auth('user', 'pass')
    page = @agent.get("http://localhost/digest_auth")
    assert_equal('You are authenticated', page.body)
  end

  def test_no_duplicate_headers
    block_called = false
    @agent.pre_connect_hooks << lambda { |params|
      block_called = true
      params[:request].to_hash.each do |k,v|
        assert_equal(1, v.length)
      end
    }
    @agent.basic_auth('user', 'pass')
    page = @agent.get("http://localhost/digest_auth")
    assert block_called
  end

  def test_post_auth_success
    class << @agent
      alias :old_fetch_page :fetch_page
      attr_accessor :requests
      def fetch_page(args)
        @requests ||= []
        x = old_fetch_page(args)
        @requests << args[:verb]
        x
      end
    end
    @agent.basic_auth('user', 'pass')
    page = @agent.post("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
    assert_equal(2, @agent.requests.length)
    r1 = @agent.requests[0]
    r2 = @agent.requests[1]
    assert_equal(r1, r2)
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
