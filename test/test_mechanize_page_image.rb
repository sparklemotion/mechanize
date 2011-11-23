require 'mechanize/test_case'

class TestMechanizePageImage < Mechanize::TestCase

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

end

