$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class ResponseCodeMechTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_redirect
    @agent.get("http://localhost:#{PORT}/response_code?code=300")
    assert_equal("http://localhost:#{PORT}/index.html",
      @agent.current_page.uri.to_s)

    @agent.get("http://localhost:#{PORT}/response_code?code=301")
    assert_equal("http://localhost:#{PORT}/index.html",
      @agent.current_page.uri.to_s)

    @agent.get("http://localhost:#{PORT}/response_code?code=302")
    assert_equal("http://localhost:#{PORT}/index.html",
      @agent.current_page.uri.to_s)

    @agent.get("http://localhost:#{PORT}/response_code?code=303")
    assert_equal("http://localhost:#{PORT}/index.html",
      @agent.current_page.uri.to_s)

    @agent.get("http://localhost:#{PORT}/response_code?code=307")
    assert_equal("http://localhost:#{PORT}/index.html",
      @agent.current_page.uri.to_s)
  end

  def test_do_not_follow_redirect
    @agent.redirect_ok = false

    @agent.get("http://localhost:#{PORT}/response_code?code=302")
    assert_equal("http://localhost:#{PORT}/response_code?code=302",
      @agent.current_page.uri.to_s)
  end

  def test_error
    @agent = WWW::Mechanize.new
    begin
      @agent.get("http://localhost:#{PORT}/response_code?code=500")
    rescue WWW::Mechanize::ResponseCodeError => err
      assert_equal("500", err.response_code)
    end
  end
end
