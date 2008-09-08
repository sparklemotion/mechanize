require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class SSLServerTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_ssl_request
    non_ssl_page = @agent.get("http://localhost/form_test.html")
    ssl_page = @agent.get("https://localhost/form_test.html")
    assert_equal(non_ssl_page.body.length, ssl_page.body.length)
  end

  def test_ssl_request_verify
    non_ssl_page = @agent.get("http://localhost/form_test.html")
    @agent.ca_file = 'data/server.crt'
    ssl_page = @agent.get("https://localhost/form_test.html")
    assert_equal(non_ssl_page.body.length, ssl_page.body.length)
  end
end
