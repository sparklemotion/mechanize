$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class SSLServerTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_ssl_request
    non_ssl_page = @agent.get("http://localhost:#{PORT}/form_test.html")
    ssl_page = @agent.get("https://localhost:#{SSLPORT}/form_test.html")
    assert_equal(non_ssl_page.body.length, ssl_page.body.length)
  end

  def test_ssl_request_verify
    non_ssl_page = @agent.get("http://localhost:#{PORT}/form_test.html")
    @agent.ca_file = 'data/server.crt'
    ssl_page = @agent.get("https://localhost:#{SSLPORT}/form_test.html")
    assert_equal(non_ssl_page.body.length, ssl_page.body.length)
  end
end
