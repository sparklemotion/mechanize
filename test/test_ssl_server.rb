require 'mechanize/test_case'

class SSLServerTest < Mechanize::TestCase
  def test_ssl_request
    non_ssl_page = @mech.get("http://localhost/form_test.html")
    ssl_page = @mech.get("https://localhost/form_test.html")
    assert_equal(non_ssl_page.body.length, ssl_page.body.length)
  end

  def test_ssl_request_verify
    non_ssl_page = @mech.get("http://localhost/form_test.html")
    @mech.ca_file = 'data/server.crt'
    ssl_page = @mech.get("https://localhost/form_test.html")
    assert_equal(non_ssl_page.body.length, ssl_page.body.length)
  end
end
