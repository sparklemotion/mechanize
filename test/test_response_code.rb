require 'mechanize/test_case'

class ResponseCodeMechTest < Mechanize::TestCase
  def setup
    @mech = Mechanize.new
  end

  def test_eof_error_loop
    assert_raises(Net::HTTP::Persistent::Error) {
      @mech.get("http://localhost/http_headers?Content-Length=300")
    }
  end

  def test_redirect
    @mech.get("http://localhost/response_code?code=300")
    assert_equal("http://localhost/index.html",
      @mech.current_page.uri.to_s)

    @mech.get("http://localhost/response_code?code=301")
    assert_equal("http://localhost/index.html",
      @mech.current_page.uri.to_s)

    @mech.get("http://localhost/response_code?code=302")
    assert_equal("http://localhost/index.html",
      @mech.current_page.uri.to_s)

    @mech.get("http://localhost/response_code?code=303")
    assert_equal("http://localhost/index.html",
      @mech.current_page.uri.to_s)

    @mech.get("http://localhost/response_code?code=307")
    assert_equal("http://localhost/index.html",
      @mech.current_page.uri.to_s)
  end

  def test_do_not_follow_redirect
    @mech.redirect_ok = false

    @mech.get("http://localhost/response_code?code=302")
    assert_equal("http://localhost/response_code?code=302",
      @mech.current_page.uri.to_s)
  end

  def test_error
    e = assert_raises Mechanize::ResponseCodeError do
      @mech.get "http://localhost/response_code?code=500"
    end

    assert_equal "500", e.response_code
  end

end

