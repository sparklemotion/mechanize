require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class RefererTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_no_referer
    page = @agent.get("http://localhost/referer")
    assert_equal('', page.body)
  end

  def test_send_referer
    page = @agent.get("http://localhost/tc_referer.html")
    page = @agent.click page.links.first
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_fetch_two
    page1 = @agent.get("http://localhost/tc_referer.html")
    page2 = @agent.get("http://localhost/tc_pretty_print.html")
    page = @agent.click page1.links.first
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_fetch_two_first
    page1 = @agent.get("http://localhost/tc_referer.html")
    page2 = @agent.get("http://localhost/tc_pretty_print.html")
    page = @agent.click page1.links.first
    assert_equal("http://localhost/tc_referer.html", page.body)
  end

  def test_post_form
    page1 = @agent.get("http://localhost/tc_referer.html")
    page2 = @agent.get("http://localhost/tc_pretty_print.html")
    page = @agent.submit page1.forms.first
    assert_equal("http://localhost/tc_referer.html", page.body)
  end
end
