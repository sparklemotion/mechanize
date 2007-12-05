$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestRelativeLinks < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_dot_dot_slash
    @page = @agent.get("http://localhost/relative/tc_relative_links.html")
    page = @page.links.first.click
    assert_equal('http://localhost/tc_relative_links.html', @agent.current_page.uri.to_s)
  end

  def test_too_many_dots
    @page = @agent.get("http://localhost/relative/tc_relative_links.html")
    page = @page.links.text('too many dots').click
    assert_not_nil(page)
    assert_equal('http://localhost/tc_relative_links.html', page.uri.to_s)
  end

  def test_go_forward
    @page = @agent.get("http://localhost/tc_relative_links.html")
    @page = @page.links.first.click
    assert_equal('http://localhost/relative/tc_relative_links.html', @agent.current_page.uri.to_s)
  end

  def test_frame_dot_dot_slash
    @page = @agent.get("http://localhost/relative/tc_relative_links.html")
    page = @agent.click(@page.frames.text('frame1'))
    assert_equal('http://localhost/tc_relative_links.html', @agent.current_page.uri.to_s)
  end

  def test_frame_forward_back_forward
    @page = @agent.get("http://localhost/tc_relative_links.html")
    page1 = @agent.click @page.frames.name('frame1')
    assert_equal('http://localhost/relative/tc_relative_links.html', @agent.current_page.uri.to_s)
    page2 = @agent.click @page.frames.name('frame2')
    assert_equal('http://localhost/relative/tc_relative_links.html', @agent.current_page.uri.to_s)
  end
end
