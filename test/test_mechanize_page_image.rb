require 'mechanize/test_case'

class TestMechanizePageImage < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example/'
    @empty_page = Mechanize::Page.new(nil, {'content-type' => 'text/html'})
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

  def test_image_extname
    page = html_page <<-BODY
<img src="a.jpg">
    BODY
    assert_equal ".jpg", page.images.first.extname

    page = html_page <<-BODY
<img src="a.PNG">
    BODY
    assert_equal ".PNG", page.images.first.extname

    page = html_page <<-BODY
<img src="unknown.aaa">
    BODY
    assert_equal ".aaa", page.images.first.extname

    page = html_page <<-BODY
<img src="nosuffiximage">
    BODY
    assert_equal "", page.images.first.extname

    page = html_page <<-BODY
<img width="1" height="1">
    BODY
    assert_nil page.images.first.extname
  end

  def test_image_mime_type
    page = html_page <<-BODY
<img src="a.jpg">
    BODY
    assert_equal "image/jpeg", page.images.first.mime_type

    page = html_page <<-BODY
<img src="a.PNG">
    BODY
    assert_equal "image/png", page.images.first.mime_type

    page = html_page <<-BODY
<img src="unknown.aaa">
    BODY
    assert_nil page.images.first.mime_type

    page = html_page <<-BODY
<img src="nosuffiximage">
    BODY
    assert_nil page.images.first.mime_type
  end

  def test_image_fetch
    page = html_page <<-BODY
<img src="http://localhost/button.jpg">
    BODY

    agent = Mechanize.new
    page.mech = agent
    fetched = page.images.first.fetch

    assert_equal fetched, agent.page
    assert_equal "http://localhost/button.jpg", fetched.uri.to_s
    assert_equal "http://example/", requests.first['Referer']
  end

  def relative?(image)
    image.__send__(:relative?)
  end

  def test_image_fetch_referer_http_page_rel_src
    #            | rel-src http-src https-src
    # http page  | *page*    page     page
    # https page |  page     empty    empty
    agent = Mechanize.new
    page = html_page '<img src="./button.jpg">'
    page.mech = agent
    page.images.first.fetch

    assert_equal 'http', page.uri.scheme
    assert_equal true, relative?(page.images.first)
    assert_equal "http://example/", requests.first['Referer']
  end

  def test_image_fetch_referer_http_page_abs_src
    #            | rel-src http-src https-src
    # http page  |  page    *page*    *page*
    # https page |  page     empty    empty
    agent = Mechanize.new
    page = html_page '<img src="http://localhost/button.jpg">'
    page.mech = agent
    page.images.first.fetch

    assert_equal 'http', page.uri.scheme
    assert_equal false, relative?(page.images.first)
    assert_equal "http://example/", requests.first['Referer']
  end

  def test_image_fetch_referer_https_page_rel_src
    #            | rel-src http-src https-src
    # http page  |  page     page     page
    # https page | *page*    empty    empty
    agent = Mechanize.new
    page = html_page '<img src="./button.jpg">'
    page.uri = URI 'https://example/'
    page.mech = agent
    page.images.first.fetch

    assert_equal 'https', page.uri.scheme
    assert_equal true, relative?(page.images.first)
    assert_equal "https://example/", requests.first['Referer']
  end

  def test_image_fetch_referer_https_page_abs_src
    #            | rel-src http-src https-src
    # http page  |  page     page     page
    # https page |  page    *empty*  *empty*
    agent = Mechanize.new
    page = html_page '<img src="http://localhost/button.jpg">'
    page.uri = URI 'https://example/'
    page.mech = agent
    page.images.first.fetch

    assert_equal 'https', page.uri.scheme
    assert_equal false, relative?(page.images.first)
    assert_equal nil, requests.first['Referer']
  end

  def image_referer_uri(page)
    page.images.first.__send__(:image_referer).uri
  end

  def test_image_referer_http_page_abs_src
    page = html_page '<img src="http://localhost/button.jpg">'

    assert_equal 'http', page.uri.scheme
    assert_equal @uri, image_referer_uri(page)
  end

  def test_image_referer_http_page_rel_src
    page = html_page '<img src="./button.jpg">'

    assert_equal 'http', page.uri.scheme
    assert_equal @uri, image_referer_uri(page)
  end

  def test_image_referer_https_page_abs_src
    page = html_page '<img src="http://localhost/button.jpg">'
    page.uri = URI 'https://example/'

    assert_equal 'https', page.uri.scheme
    assert_nil image_referer_uri(page)
  end

  def test_image_referer_https_page_rel_src
    page = html_page '<img src="./button.jpg">'
    page.uri = URI 'https://example/'

    assert_equal 'https', page.uri.scheme
    assert_equal URI('https://example/'), image_referer_uri(page)
  end

  def test_image_referer_when_no_initpage
    agent = Mechanize.new
    image = Mechanize::Page::Image.new({'src'=>'http://localhost/button.jpg'}, nil)

    assert_nil image.page
    assert_nil image.__send__(:image_referer).uri
  end

  # test Tempfile.open{|tmp| page.save(tmp.path) } does not work
  #   because tmp.path already exists when Parser.find_free_name starts check
  class TestMechanizePageImageWithTempfile < Mechanize::TestCase

    def setup
      super

      @uri = URI 'http://example/'

      @tmp_save = Tempfile.open('mech_test__mechanize_page_image_save')
      @save_path = @tmp_save.path
      @tmp_save.close(true)

      @tmp_download = Tempfile.open('mech_test__mechanize_page_image_download')
      @download_path = @tmp_download.path
      @tmp_download.close(true)
    end

    def teardown
      super
      File.unlink @save_path if File.exist? @save_path
      File.unlink @download_path if File.exist? @download_path
    end

    def test_image_save
      page = html_page <<-BODY
<img src="http://localhost/button.jpg">
    BODY

      agent = Mechanize.new
      page.mech = agent
      agent.__send__(:add_to_history, page)
      page.images.first.save(@save_path)

      assert_equal 983, File.size(@save_path)
      assert_equal ["http://example/", "http://localhost/button.jpg"], agent.history.map{|p| p.uri.to_s}
      # visited? does not returns Boolean
      assert agent.visited?("http://localhost/button.jpg")
    end

    def test_image_download
      page = html_page <<-BODY
<img src="http://localhost/button.jpg">
    BODY

      agent = Mechanize.new
      page.mech = agent
      agent.__send__(:add_to_history, page)
      page.images.first.download(@download_path)

      assert_equal 983, File.size(@download_path)
      assert_equal ["http://example/"], agent.history.map{|p| p.uri.to_s}
      # visited? does not returns Boolean
      assert_nil agent.visited?("http://localhost/button.jpg")
    end
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
