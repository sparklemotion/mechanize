$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class FormsMechTest < Test::Unit::TestCase
  include TestMethods

  def test_redirect
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    agent.get("http://localhost:#{@port}/response_code?code=301")
    assert_equal("http://localhost:#{@port}/index.html",
      agent.current_page.uri.to_s)

    agent.get("http://localhost:#{@port}/response_code?code=302")
    assert_equal("http://localhost:#{@port}/index.html",
      agent.current_page.uri.to_s)
  end

  def test_error
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    begin
      agent.get("http://localhost:#{@port}/response_code?code=500")
    rescue WWW::ResponseCodeError => err
      assert_equal("500", err.response_code)
    end
  end
end
