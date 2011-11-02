require 'mechanize/test_case'

class SchemeTest < Mechanize::TestCase
  def test_file_scheme
    f = File.expand_path(__FILE__)
    page = @mech.get("file://#{f}")
    assert_equal(File.read(f), page.body)
  end

  def test_file_scheme_parses_html
    f = File.expand_path(
               File.join(File.dirname(__FILE__), "htdocs", 'google.html'))
    page = @mech.get("file://#{f}")
    assert_equal(File.read(f), page.body)
    assert_kind_of(Mechanize::Page, page)
  end

  def test_file_scheme_supports_directories
    f = File.expand_path(File.join(File.dirname(__FILE__), "htdocs"))
    page = @mech.get("file://#{f}")
    assert_equal(Dir[File.join(f, '*')].length, page.links.length)
    assert_kind_of(Mechanize::Page, page)
  end

  def test_click_file_link
    f = File.expand_path(File.join(File.dirname(__FILE__), "htdocs"))
    page = @mech.get("file://#{f}")
    link = page.links.find { |l| l.text =~ /tc_follow_meta/ }

    path = URI.parse(link.href).path

    page = link.click
    assert_equal(File.read(path), page.body)

    link = page.meta_refresh.first
    page = @mech.click(link)

    assert_equal("http://localhost/index.html", @mech.history.last.uri.to_s)
  end
end
