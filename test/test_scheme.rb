require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class SchemeTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @agent.log = Class.new(Object) do
      def method_missing(*args)
      end
    end.new
  end

  def test_file_scheme
    f = File.expand_path(__FILE__)
    page = @agent.get("file://#{f}")
    assert_equal(File.read(f), page.body)
  end

  def test_file_scheme_parses_html
    f = File.expand_path(
               File.join(File.dirname(__FILE__), "htdocs", 'google.html'))
    page = @agent.get("file://#{f}")
    assert_equal(File.read(f), page.body)
    assert_kind_of(WWW::Mechanize::Page, page)
  end

  def test_file_scheme_supports_directories
    f = File.expand_path(File.join(File.dirname(__FILE__), "htdocs"))
    page = @agent.get("file://#{f}")
    assert_equal(Dir[File.join(f, '*')].length, page.links.length)
    assert_kind_of(WWW::Mechanize::Page, page)
  end

  def test_click_file_link
    f = File.expand_path(File.join(File.dirname(__FILE__), "htdocs"))
    page = @agent.get("file://#{f}")
    link = page.links.find { |l| l.text =~ /tc_follow_meta/ }
    assert_not_nil(link)
    path = URI.parse(link.href).path
    
    page = link.click
    assert_equal(File.read(path), page.body)

    link = page.meta.first
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost/index.html", @agent.history.last.uri.to_s)
  end
end
