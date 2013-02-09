require 'mechanize/test_case'

class TestMechanizePage < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example/'
  end

  def test_initialize_good_content_type
    page = Mechanize::Page.new
    assert_equal('text/html', page.content_type)

    [
      'text/html',
      'Text/HTML',
      'text/html; charset=UTF-8',
      'text/html ; charset=US-ASCII',
      'application/xhtml+xml',
      'Application/XHTML+XML',
      'application/xhtml+xml; charset=UTF-8',
      'application/xhtml+xml ; charset=US-ASCII',
    ].each { |content_type|
      page = Mechanize::Page.new(URI('http://example/'),
        { 'content-type' => content_type }, 'hello', '200')

      assert_equal(content_type, page.content_type, content_type)
    }
  end

  def test_initialize_bad_content_type
    [
      'text/xml',
      'text/xhtml',
      'text/htmlfu',
      'footext/html',
      'application/xhtml+xmlfu',
      'fooapplication/xhtml+xml',
    ].each { |content_type|
      page = Mechanize::Page.new(URI('http://example/'),
        { 'content-type' => content_type }, 'hello', '200')

      assert_equal(content_type, page.content_type, content_type)
    }
  end

  def test_frames
    page = html_page <<-BODY
<TITLE>A simple frameset document</TITLE>
<FRAMESET cols="20%, 80%">
  <FRAMESET rows="100, 200">
  <FRAME name="frame1" src="/google.html">
  <FRAME name="frame2" src="/form_test.html">
  </FRAMESET>
  <FRAMESET rows="100, 200">
  <FRAME name="frame3" src="/file_upload.html">
  <IFRAME src="http://google.com/" name="frame4"></IFRAME>
  </FRAMESET>
</FRAMESET>
    BODY

    assert_equal 3, page.frames.size
    assert_equal "frame1",       page.frames[0].name
    assert_equal "/google.html", page.frames[0].src
    assert_equal "Google",       page.frames[0].content.title

    assert_equal "frame2",          page.frames[1].name
    assert_equal "/form_test.html", page.frames[1].src
    assert_equal "Page Title",      page.frames[1].content.title

    assert_equal "frame3",            page.frames[2].name
    assert_equal "/file_upload.html", page.frames[2].src
    assert_equal "File Upload Form",  page.frames[2].content.title
  end

  def test_iframes
    page = html_page <<-BODY
<TITLE>A simple frameset document</TITLE>
<FRAME name="frame1" src="/google.html">
<IFRAME src="/file_upload.html" name="frame4">
</IFRAME>
    BODY

    assert_equal 1, page.iframes.size

    assert_equal "frame4",            page.iframes.first.name
    assert_equal "/file_upload.html", page.iframes.first.src
    assert_equal "File Upload Form",  page.iframes.first.content.title
  end

  def test_image_with
    page = html_page <<-BODY
<img src="a.jpg">
<img src="b.jpg">
<img src="c.png">
    BODY

    assert_equal "http://example/b.jpg",
                 page.image_with(:src => 'b.jpg').url.to_s
  end

  def test_images_with
    page = html_page <<-BODY
<img src="a.jpg">
<img src="b.jpg">
<img src="c.png">
    BODY

    images = page.images_with(:src => /jpg\Z/).map { |img| img.url.to_s }
    assert_equal %w[http://example/a.jpg http://example/b.jpg], images
  end

  def test_links
    page = html_page <<-BODY
<a href="foo.html">
    BODY

    assert_equal page.links.first.href, "foo.html"
  end

  def test_parser_no_attributes
    page = html_page <<-BODY
<html>
  <meta>
  <head><title></title>
  <body>
    <a>Hello</a>
    <a><img /></a>
    <form>
      <input />
      <select>
        <option />
      </select>
      <textarea></textarea>
    </form>
    <frame></frame>
  </body>
</html>
    BODY

    # HACK weak assertion
    assert_kind_of Nokogiri::HTML::Document, page.root
  end

  def test_search_links
    page = html_page <<-BODY
<html>
  <meta>
  <head><title></title>
  <body>
    <span id="spany">
      <a href="b.html">b</a>
      <a href="a.html">a</a>
    </span>
    <a href="6.html">6</a>
  </body>
</html>
    BODY

    links = page.links_with(:search => "#spany a")

    assert_equal 2, links.size
    assert_equal "b.html", links[0].href
    assert_equal "b",      links[0].text

    assert_equal "a.html", links[1].href
    assert_equal "a",      links[1].text
  end

  def test_search_images
    page = html_page <<-BODY
<html>
  <meta>
  <head><title></title>
  <body>
    <img src="a.jpg" class="pretty">
    <img src="b.jpg">
    <img src="c.png" class="pretty">
  </body>
</html>
    BODY

    images = page.images_with(:search => "//img[@class='pretty']")

    assert_equal 2, images.size
    assert_equal "pretty", images[0].dom_class
    assert_equal "a.jpg", images[0].src

    assert_equal "pretty", images[1].dom_class
    assert_equal "c.png", images[1].src
  end

end

