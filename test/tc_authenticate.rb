$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class BasicAuthTest < Test::Unit::TestCase
  include TestMethods

  def test_auth_success
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    agent.basic_auth('mech', 'password')
    page = agent.get("http://localhost:#{@port}/htpasswd_auth")
    assert_equal('You are authenticated', page.body)
  end

  def test_auth_failure
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    begin
      page = agent.get("http://localhost:#{@port}/htpasswd_auth")
    rescue WWW::ResponseCodeError => e
      assert_equal("401", e.response_code)
    end
  end

end
