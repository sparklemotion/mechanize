require 'mechanize/test_case'

class TestRelativeLinks < Mechanize::TestCase
  def test_dot_dot_slash
    @page = @mech.get("http://localhost/relative/tc_relative_links.html")
    @page.links.first.click
    assert_equal('http://localhost/tc_relative_links.html', @mech.current_page.uri.to_s)
  end

  def test_too_many_dots
    @page = @mech.get("http://localhost/relative/tc_relative_links.html")
    page = @page.link_with(:text => 'too many dots').click

    assert_equal('http://localhost/tc_relative_links.html', page.uri.to_s)
  end

  def test_go_forward
    @page = @mech.get("http://localhost/tc_relative_links.html")
    @page = @page.links.first.click
    assert_equal('http://localhost/relative/tc_relative_links.html', @mech.current_page.uri.to_s)
  end

  def test_frame_dot_dot_slash
    @page = @mech.get("http://localhost/relative/tc_relative_links.html")
    @mech.click(@page.frame_with(:text => 'frame1'))
    assert_equal('http://localhost/tc_relative_links.html', @mech.current_page.uri.to_s)
  end

  def test_frame_forward_back_forward
    @page = @mech.get("http://localhost/tc_relative_links.html")
    @mech.click @page.frame_with(:name => 'frame1')
    assert_equal('http://localhost/relative/tc_relative_links.html', @mech.current_page.uri.to_s)
    @mech.click @page.frame_with(:name => 'frame2')
    assert_equal('http://localhost/relative/tc_relative_links.html', @mech.current_page.uri.to_s)
  end
end
