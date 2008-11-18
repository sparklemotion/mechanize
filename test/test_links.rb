require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class LinksMechTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_unsupported_link_types
    page = @agent.get("http://google.com/tc_links.html")
    link = page.link_with(:text => 'javascript link')
    assert_raise(WWW::Mechanize::UnsupportedSchemeError) {
      link.click
    }

    @agent.scheme_handlers['javascript'] = lambda { |my_link, my_page|
      URI.parse('http://localhost/tc_links.html')
    }
    assert_nothing_raised {
      link.click
    }
  end

  def test_link_with_no_path
    page = @agent.get("http://localhost/relative/tc_relative_links.html")
    page = page.link_with(:text => 'just the query string').click
    assert_equal('http://localhost/relative/tc_relative_links.html?a=b', page.uri.to_s)
  end

  def test_base
    page = @agent.get("http://google.com/tc_base_link.html")
    page = page.links.first.click
    assert @agent.visited?("http://localhost/index.html")
  end

  def test_find_meta
    page = @agent.get("http://localhost/find_link.html")
    assert_equal(3, page.meta.length)
    assert_equal(%w{
      http://www.drphil.com/
      http://www.upcase.com/
      http://tenderlovemaking.com/ }.sort,
      page.meta.map { |x| x.href.downcase }.sort)
  end

  def test_find_link
    page = @agent.get("http://localhost/find_link.html")
    assert_equal(18, page.links.length)
  end

  def test_alt_text
    page = @agent.get("http://localhost/alt_text.html")
    assert_equal(5, page.links.length)
    assert_equal(1, page.meta.length)

    assert_equal('', page.meta.first.text)
    assert_equal('alt text', page.link_with(:href => 'alt_text.html').text)
    assert_equal('', page.link_with(:href => 'no_alt_text.html').text)
    assert_equal('no image', page.link_with(:href => 'no_image.html').text)
    assert_equal('', page.link_with(:href => 'no_text.html').text)
    assert_equal('', page.link_with(:href => 'nil_alt_text.html').text)
  end

  def test_click_link
    @agent.user_agent_alias = 'Mac Safari'
    page = @agent.get("http://localhost/frame_test.html")
    link = page.link_with(:text => "Form Test")
    assert_not_nil(link)
    assert_equal('Form Test', link.text)
    page = @agent.click(link)
    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_method
    page = @agent.get("http://localhost/frame_test.html")
    link = page.link_with(:text => "Form Test")
    assert_not_nil(link)
    assert_equal('Form Test', link.text)
    page = link.click
    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_find_bold_link
    page = @agent.get("http://localhost/tc_links.html")
    link = page.links_with(:text => /Bold Dude/)
    assert_equal(1, link.length)
    assert_equal('Bold Dude', link.first.text)

    link = page.links_with(:text => 'Aaron James Patterson')
    assert_equal(1, link.length)
    assert_equal('Aaron James Patterson', link.first.text)

    link = page.links_with(:text => 'Aaron Patterson')
    assert_equal(1, link.length)
    assert_equal('Aaron Patterson', link.first.text)

    link = page.links_with(:text => 'Ruby Rocks!')
    assert_equal(1, link.length)
    assert_equal('Ruby Rocks!', link.first.text)
  end

  def test_link_with_encoded_space
    page = @agent.get("http://localhost/tc_links.html")
    link = page.link_with(:text => 'encoded space')
    page = @agent.click link
  end

  def test_link_with_space
    page = @agent.get("http://localhost/tc_links.html")
    link = page.link_with(:text => 'not encoded space')
    page = @agent.click link
  end

  def test_link_with_unusual_characters
    page = @agent.get("http://localhost/tc_links.html")
    link = page.link_with(:text => 'unusual characters')
    assert_nothing_raised { @agent.click link }
  end
end
