$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class BasicAuthTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_auth_success
    @agent.basic_auth('user', 'pass')
    page = @agent.get("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
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
