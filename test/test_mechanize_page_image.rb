require 'mechanize/test_case'

class TestMechanizePageImage < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example/'
  end

  def test_image_attributes
    page = html_page <<-BODY
<img src="a.jpg" alt="alt" width="100" height="200" title="title" id="id" class="class">
    BODY
    assert_equal "a.jpg", page.images.first.src
    assert_equal "alt", page.images.first.alt
    assert_equal "100", page.images.first.width
    assert_equal "200", page.images.first.height
    assert_equal "title", page.images.first.title
    assert_equal "id", page.images.first.dom_id
    assert_equal "class", page.images.first.dom_class
  end

  def test_image_attributes_nil
    page = html_page <<-BODY
<img>
    BODY
    assert_nil page.images.first.src
    assert_nil page.images.first.alt
    assert_nil page.images.first.width
    assert_nil page.images.first.height
    assert_nil page.images.first.title
    assert_nil page.images.first.dom_id
    assert_nil page.images.first.dom_class
  end

  def test_image_caption
    page = html_page <<-BODY
<img src="a.jpg" alt="alt">
    BODY
    assert_equal "alt", page.images.first.caption

    page = html_page <<-BODY
<img src="a.jpg" title="title">
    BODY
    assert_equal "title", page.images.first.caption

    page = html_page <<-BODY
<img src="a.jpg" alt="alt" title="title">
    BODY
    assert_equal "title", page.images.first.caption

    page = html_page <<-BODY
<img src="a.jpg">
    BODY
    assert_equal "", page.images.first.caption
  end

  def test_image_url
    page = html_page <<-BODY
<img src="a.jpg">
    BODY

    assert_equal "http://example/a.jpg", page.images.first.url
  end

  def test_image_url_base
    page = html_page <<-BODY
<head>
  <base href="http://other.example/">
</head>
<body>
  <img src="a.jpg">
</body>
    BODY

    assert_equal "http://other.example/a.jpg", page.images.first.url
  end

  def test_image_with
    page = html_page <<-BODY
<img src="a.jpg">
<img src="b.jpg">
<img src="c.png">
    BODY

    assert_equal "http://example/b.jpg", page.image_with(:src => 'b.jpg').url
  end

  def test_images_with
    page = html_page <<-BODY
<img src="a.jpg">
<img src="b.jpg">
<img src="c.png">
    BODY

    images = page.images_with(:src => /jpg\Z/).map{|img| img.url}
    assert_equal ["http://example/a.jpg", "http://example/b.jpg"], images
  end

end
