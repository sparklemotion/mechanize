require 'mechanize/test_case'

class TestMechanizePage < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example/'
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

