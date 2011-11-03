require 'mechanize/test_case'

class TestMechanizePage < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example/'
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

  def test_images
    page = html_page <<-BODY
<img src="a.jpg">
    BODY

    assert_equal page.images.first.url, "http://example/a.jpg"
  end

  def test_images_base
    page = html_page <<-BODY
<head>
  <base href="http://other.example/">
</head>
<body>
  <img src="a.jpg">
</body>
    BODY

    assert_equal page.images.first.url, "http://other.example/a.jpg"
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

end

