require 'mechanize/test_case'

class TestMechanizeLink < Mechanize::TestCase

  def test_click
    page = @mech.get("http://localhost/frame_test.html")
    link = page.link_with(:text => "Form Test")

    assert_equal('Form Test', link.text)
    page = link.click
    assert_equal("http://localhost/form_test.html",
      @mech.history.last.uri.to_s)
  end

  def test_click_base
    page = @mech.get("http://google.com/tc_base_link.html")
    page = page.links.first.click
    assert @mech.visited?("http://localhost/index.html")
  end

  def test_click_unsupported_scheme
    page = @mech.get("http://google.com/tc_links.html")
    link = page.link_with(:text => 'javascript link')
    assert_raises Mechanize::UnsupportedSchemeError do
      link.click
    end

    @mech.scheme_handlers['javascript'] = lambda { |my_link, my_page|
      URI.parse('http://localhost/tc_links.html')
    }

    link.click

    # HACK no assertion
  end

  def test_click_empty_href
    page = @mech.get("http://google.com/tc_links.html?q=test#anchor")
    link = page.link_with(:text => 'empty href')

    new_page = link.click
    assert_equal "http://google.com/tc_links.html?q=test", new_page.uri.to_s
  end

  def test_text_alt_text
    page = @mech.get("http://localhost/alt_text.html")
    assert_equal(5, page.links.length)
    assert_equal(1, page.meta_refresh.length)

    assert_equal '',         page.meta_refresh.first.text
    assert_equal 'alt text', page.link_with(:href => 'alt_text.html').text
    assert_equal '',         page.link_with(:href => 'no_alt_text.html').text
    assert_equal 'no image', page.link_with(:href => 'no_image.html').text
    assert_equal '',         page.link_with(:href => 'no_text.html').text
    assert_equal '',         page.link_with(:href => 'nil_alt_text.html').text
  end

  def test_uri_escaped
    doc = Nokogiri::HTML::Document.new

    node = Nokogiri::XML::Node.new('foo', doc)
    node['href'] = 'http://foo.bar/%20baz'

    link = Mechanize::Page::Link.new(node, nil, nil)

    assert_equal 'http://foo.bar/%20baz', link.uri.to_s
  end

  def test_uri_no_path
    page = @mech.get("http://localhost/relative/tc_relative_links.html")
    page = page.link_with(:text => 'just the query string').click
    assert_equal('http://localhost/relative/tc_relative_links.html?a=b',
                 page.uri.to_s)
  end

  def test_uri_weird
    doc = Nokogiri::HTML::Document.new

    node = Nokogiri::XML::Node.new('foo', doc)
    node['href'] = 'http://foo.bar/ baz'

    link = Mechanize::Page::Link.new(node, nil, nil)

    assert_equal 'http://foo.bar/%20baz', link.uri.to_s
  end

end

