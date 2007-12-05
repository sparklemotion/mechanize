$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class RefererTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_no_referer
    page = @agent.get("http://localhost:#{PORT}/referer")
    assert_equal('', page.body)
  end

  def test_send_referer
    page = @agent.get("http://localhost:#{PORT}/tc_referer.html")
    page = @agent.click page.links.first
    assert_equal("http://localhost:#{PORT}/tc_referer.html", page.body)
  end

  def test_fetch_two
    page1 = @agent.get("http://localhost:#{PORT}/tc_referer.html")
    page2 = @agent.get("http://localhost:#{PORT}/tc_pretty_print.html")
    page = @agent.click page1.links.first
    assert_equal("http://localhost:#{PORT}/tc_referer.html", page.body)
  end

  def test_fetch_two_first
    page1 = @agent.get("http://localhost:#{PORT}/tc_referer.html")
    page2 = @agent.get("http://localhost:#{PORT}/tc_pretty_print.html")
    page = @agent.click page1.links
    assert_equal("http://localhost:#{PORT}/tc_referer.html", page.body)
  end

  def test_post_form
    page1 = @agent.get("http://localhost:#{PORT}/tc_referer.html")
    page2 = @agent.get("http://localhost:#{PORT}/tc_pretty_print.html")
    page = @agent.submit page1.forms.first
    assert_equal("http://localhost:#{PORT}/tc_referer.html", page.body)
  end
end
