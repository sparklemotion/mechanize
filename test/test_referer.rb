require "helper"

class RefererTest < MiniTest::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_no_referer
    page = @agent.get("http://localhost/referer")
    assert_equal('', page.body)
  end

  def test_send_referer
    page = @agent.get("http://localhost/tc_referer.html")
    page = @agent.click page.links[0]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_send_referer_noreferrer
    page = @agent.get("http://localhost/tc_referer.html")
    page = @agent.click page.links[3]
    assert_equal("", page.body)
  end

  def test_fetch_two
    page1 = @agent.get("http://localhost/tc_referer.html")
    @agent.get("http://localhost/tc_pretty_print.html")
    page = @agent.click page1.links[0]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_fetch_two_first
    page1 = @agent.get("http://localhost/tc_referer.html")
    @agent.get("http://localhost/tc_pretty_print.html")
    page = @agent.click page1.links[0]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_post_form
    page1 = @agent.get("http://localhost/tc_referer.html")
    @agent.get("http://localhost/tc_pretty_print.html")
    page = @agent.submit page1.forms.first
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_http_to_https
    page = @agent.get("http://localhost/tc_referer.html")
    page = @agent.click page.links[2]
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_http_to_https_noreferrer
    page = @agent.get("http://localhost/tc_referer.html")
    page = @agent.click page.links[5]
    assert_equal("", page.body)
  end

  def test_https_to_https
    page = @agent.get("https://localhost/tc_referer.html")
    page = @agent.click page.links[2]
    assert_equal("https://localhost/tc_referer.html", page.body)
  end

  def test_https_to_https_noreferrer
    page = @agent.get("https://localhost/tc_referer.html")
    page = @agent.click page.links[5]
    assert_equal("", page.body)
  end

  def test_https_to_http
    page = @agent.get("https://localhost/tc_referer.html")
    page = @agent.click page.links[1]
    assert_equal("", page.body)
  end

  def test_https_to_http_noreferrer
    page = @agent.get("https://localhost/tc_referer.html")
    page = @agent.click page.links[4]
    assert_equal("", page.body)
  end
end
