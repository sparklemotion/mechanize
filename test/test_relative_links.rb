require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestRelativeLinks < Test::Unit::TestCase
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
    page = @page.link_with(:text => 'too many dots').click
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
    page = @agent.click(@page.frame_with(:text => 'frame1'))
    assert_equal('http://localhost/tc_relative_links.html', @agent.current_page.uri.to_s)
  end

  def test_frame_forward_back_forward
    @page = @agent.get("http://localhost/tc_relative_links.html")
    page1 = @agent.click @page.frame_with(:name => 'frame1')
    assert_equal('http://localhost/relative/tc_relative_links.html', @agent.current_page.uri.to_s)
    page2 = @agent.click @page.frame_with(:name => 'frame2')
    assert_equal('http://localhost/relative/tc_relative_links.html', @agent.current_page.uri.to_s)
  end
end
