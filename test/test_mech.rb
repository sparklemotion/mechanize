require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestMechMethods < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_get_with_tilde
    page = @agent.get('http://localhost/?foo=~2')
    assert_equal('http://localhost/?foo=~2', page.uri.to_s)
  end

  def test_parser_can_be_set
    @agent.html_parser = {}
    assert_raises(NoMethodError) {
      @agent.get('http://localhost/?foo=~2').links
    }
  end

  def test_submit_takes_arbirary_headers
    page = @agent.get('http://localhost:2000/form_no_action.html')
    assert form = page.forms.first
    form.action = '/http_headers'
    page = @agent.submit(form, nil, { 'foo' => 'bar' })
    headers = Hash[*(
      page.body.split("\n").map { |x| x.split('|') }.flatten
    )]
    assert_equal 'bar', headers['foo']
  end

  def test_get_with_params
    page = @agent.get('http://localhost/', { :q => 'hello' })
    assert_equal('http://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_with_upper_http
    page = @agent.get('HTTP://localhost/', { :q => 'hello' })
    assert_equal('HTTP://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_no_referer
    requests = []
    @agent.pre_connect_hooks << lambda { |params|
      requests << params[:request]
    }

    @agent.get('http://localhost/')
    @agent.get('http://localhost/')
    assert_equal(2, requests.length)
    requests.each do |request|
      assert_nil request['referer']
    end
  end

  def test_with_anchor
    page = @agent.get('http://localhost/?foo=bar&#34;')
    assert_equal('http://localhost/?foo=bar%22', page.uri.to_s)
  end

  def test_post_connect_hook_gets_called
    response = nil
    @agent.post_connect_hooks << lambda { |params|
      response = params[:response]
    }

    @agent.get('http://localhost/')
    assert(response)
  end

  def test_get_with_referer
    request = nil
    @agent.pre_connect_hooks << lambda { |params|
      request = params[:request]
    }

    @agent.get('http://localhost/', URI.parse('http://google.com/'))
    assert_equal 'http://google.com/', request['Referer']

    @agent.get('http://localhost/', [], 'http://tenderlovemaking.com/')
    assert_equal 'http://tenderlovemaking.com/', request['Referer']
  end
  
  def test_get_with_file_referer
    assert_nothing_raised do
      @agent.get('http://localhost', [], WWW::Mechanize::File.new(URI.parse('http://tenderlovemaking.com/crossdomain.xml')))
    end
  end

  def test_weird_url
    assert_nothing_raised {
      @agent.get('http://localhost/?action=bing&bang=boom=1|a=|b=|c=')
    }
    assert_nothing_raised {
      @agent.get('http://localhost/?a=b&#038;b=c&#038;c=d')
    }
    assert_nothing_raised {
      @agent.get("http://localhost/?a=#{[0xd6].pack('U')}")
    }
  end

  unless RUBY_VERSION >= '1.9.0'
    def test_kcode_url
      $KCODE = 'u'
      page = @agent.get("http://localhost/?a=#{[0xd6].pack('U')}")
      assert_not_nil(page)
      assert_equal('http://localhost/?a=%D6', page.uri.to_s)
      $KCODE = 'NONE'
    end
  end

  def test_history
    0.upto(25) do |i|
      assert_equal(i, @agent.history.size)
      page = @agent.get("http://localhost/")
    end
    page = @agent.get("http://localhost/form_test.html")

    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
    assert_equal("http://localhost/",
      @agent.history[-2].uri.to_s)
    assert_equal("http://localhost/",
      @agent.history[-2].uri.to_s)

    assert_equal(true, @agent.visited?("http://localhost/"))
    assert_equal(true, @agent.visited?("/form_test.html"))
    assert_equal(false, @agent.visited?("http://google.com/"))
    assert_equal(true, @agent.visited?(page.links.first))

  end

  def test_visited
    @agent.get("http://localhost/content_type_test?ct=application/pdf")
    assert_equal(true,
      @agent.visited?("http://localhost/content_type_test?ct=application/pdf"))
    assert_equal(false,
      @agent.visited?("http://localhost/content_type_test"))
    assert_equal(false,
      @agent.visited?("http://localhost/content_type_test?ct=text/html"))
  end

  def test_visited_after_redirect
    @agent.get("http://localhost/response_code?code=302")
    assert_equal("http://localhost/index.html",
      @agent.current_page.uri.to_s)
    assert_equal(true,
                 @agent.visited?('http://localhost/response_code?code=302'))
  end

  def test_max_history
    @agent.max_history = 10
    0.upto(10) do |i|
      assert_equal(i, @agent.history.size)
      page = @agent.get("http://localhost/")
    end
    
    0.upto(10) do |i|
      assert_equal(10, @agent.history.size)
      page = @agent.get("http://localhost/")
    end
  end

  def test_max_history_order
    @agent.max_history = 2
    assert_equal(0, @agent.history.length)

    @agent.get('http://localhost/form_test.html')
    assert_equal(1, @agent.history.length)

    @agent.get('http://localhost/empty_form.html')
    assert_equal(2, @agent.history.length)

    @agent.get('http://localhost/tc_checkboxes.html')
    assert_equal(2, @agent.history.length)
    assert_equal('http://localhost/empty_form.html', @agent.history[0].uri.to_s)
    assert_equal('http://localhost/tc_checkboxes.html',
                 @agent.history[1].uri.to_s)
  end

  def test_back_button
    0.upto(5) do |i|
      assert_equal(i, @agent.history.size)
      page = @agent.get("http://localhost/")
    end
    page = @agent.get("http://localhost/form_test.html")

    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
    assert_equal("http://localhost/",
      @agent.history[-2].uri.to_s)

    assert_equal(7, @agent.history.size)
    @agent.back
    assert_equal(6, @agent.history.size)
    assert_equal("http://localhost/",
      @agent.history.last.uri.to_s)
  end

  def test_google
    page = @agent.get("http://localhost/google.html")
    search = page.forms.find { |f| f.name == "f" }
    assert_not_nil(search)
    assert_not_nil(search.field_with(:name => 'q'))
    assert_not_nil(search.field_with(:name => 'hl'))
    assert_not_nil(search.fields.find { |f| f.name == 'ie' })
  end

  def test_click
    @agent.user_agent_alias = 'Mac Safari'
    page = @agent.get("http://localhost/frame_test.html")
    link = page.link_with(:text => "Form Test")
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_hpricot
    page = @agent.get("http://localhost/frame_test.html")

    link = (page/"//a[@class='bar']").first
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_hpricot_frame
    page = @agent.get("http://localhost/frame_test.html")

    link = (page/"//frame[@name='frame2']").first
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_new_find
    page = @agent.get("http://localhost/frame_test.html")
    assert_equal(3, page.frames.size)

    find_orig = page.frames.find_all { |f| f.name == 'frame1' }
    find1 = page.frames_with(:name => 'frame1')

    find_orig.zip(find1).each { |a,b|
      assert_equal(a, b)
    }
  end

  def test_get_file
    page = @agent.get("http://localhost/frame_test.html")
    content_length = page.header['Content-Length']
    page_as_string = @agent.get_file("http://localhost/frame_test.html")
    assert_equal(content_length.to_i, page_as_string.length.to_i)
  end

  def test_transact
    page = @agent.get("http://localhost/frame_test.html")
    assert_equal(1, @agent.history.length)
    @agent.transact { |a|
      5.times {
        @agent.get("http://localhost/frame_test.html")
      }
      assert_equal(6, @agent.history.length)
    }
    assert_equal(1, @agent.history.length)
  end
end
