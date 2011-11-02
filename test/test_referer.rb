require 'mechanize/test_case'

class RefererTest < Mechanize::TestCase

  def test_no_referer
    page = @mech.get("http://localhost/referer")
    assert_equal('', page.body)
  end

  def test_send_referer
    page = @mech.get("http://localhost/tc_referer.html")
    page = @mech.click page.links[0]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_send_referer_noreferrer
    page = @mech.get("http://localhost/tc_referer.html")
    page = @mech.click page.links[3]
    assert_equal("", page.body)
  end

  def test_fetch_two
    page1 = @mech.get("http://localhost/tc_referer.html")
    @mech.get("http://localhost/tc_pretty_print.html")
    page = @mech.click page1.links[0]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_fetch_two_first
    page1 = @mech.get("http://localhost/tc_referer.html")
    @mech.get("http://localhost/tc_pretty_print.html")
    page = @mech.click page1.links[0]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_post_form
    page1 = @mech.get("http://localhost/tc_referer.html")
    @mech.get("http://localhost/tc_pretty_print.html")
    page = @mech.submit page1.forms.first
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_http_to_https
    page = @mech.get("http://localhost/tc_referer.html")
    page = @mech.click page.links[2]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_http_to_https_noreferrer
    page = @mech.get("http://localhost/tc_referer.html")
    page = @mech.click page.links[5]
    assert_equal("", page.body)
  end

  def test_https_to_https
    page = @mech.get("https://localhost/tc_referer.html")
    page = @mech.click page.links[2]
    assert_equal("https://localhost/tc_referer.html", page.body)
  end

  def test_https_to_https_noreferrer
    page = @mech.get("https://localhost/tc_referer.html")
    page = @mech.click page.links[5]
    assert_equal("", page.body)
  end

  def test_https_to_http
    page = @mech.get("https://localhost/tc_referer.html")
    page = @mech.click page.links[1]
    assert_equal("", page.body)
  end

  def test_https_to_http_noreferrer
    page = @mech.get("https://localhost/tc_referer.html")
    page = @mech.click page.links[4]
    assert_equal("", page.body)
  end

  def test_redirection_keeps_referer
    referer = 'http://localhost/?test=1'
    @mech.redirect_ok = :permanent
    page = @mech.get('http://localhost/redirect_ok', nil, referer)
    assert_equal(referer, page['X-Referer'])

    referer = 'http://localhost/?test=2'
    @mech.redirect_ok = true
    page = @mech.get('http://localhost/redirect_ok', nil, referer)
    assert_equal(referer, page['X-Referer'])
  end
end
