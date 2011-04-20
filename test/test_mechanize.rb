# coding: utf-8

require 'helper'

class TestMechanize < Test::Unit::TestCase

  KEY = OpenSSL::PKey::RSA.new 512
  name = OpenSSL::X509::Name.parse 'CN=nobody/DC=example'
  CERT = OpenSSL::X509::Certificate.new
  CERT.version = 2
  CERT.serial = 0
  CERT.not_before = Time.now
  CERT.not_after = Time.now + 60
  CERT.public_key = KEY.public_key
  CERT.subject = name
  CERT.issuer = name
  CERT.sign KEY, OpenSSL::Digest::SHA1.new

  def setup
    @agent = Mechanize.new
    @uri = URI.parse 'http://example/'
    @req = Net::HTTP::Get.new '/'

    @res = Net::HTTPOK.allocate
    @res.instance_variable_set :@code, 200
    @res.instance_variable_set :@header, {}

    @headers = if RUBY_VERSION > '1.9' then
                 %w[accept user-agent]
               else
                 %w[accept]
               end
  end

  def test_back
    0.upto(5) do |i|
      assert_equal(i, @agent.history.size)
      @agent.get("http://localhost/")
    end
    @agent.get("http://localhost/form_test.html")

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

  def test_basic_auth
    @agent.basic_auth('user', 'pass')
    page = @agent.get("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
  end

  def test_cert_key_file
    Tempfile.open 'key' do |key|
      Tempfile.open 'cert' do |cert|
        key.write KEY.to_pem
        key.rewind

        cert.write CERT.to_pem
        cert.rewind

        agent = Mechanize.new do |a|
          a.cert = cert.path
          a.key  = key.path
        end

        # Certificate#== seems broken
        assert_equal CERT.to_pem, agent.http.certificate.to_pem
      end
    end
  end

  def test_cert_key_object
    agent = Mechanize.new do |a|
      a.cert = CERT
      a.key  = KEY
    end

    assert_equal CERT, agent.http.certificate
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

  def test_click_frame_hpricot_style
    page = @agent.get("http://localhost/frame_test.html")

    link = (page/"//frame[@name='frame2']").first
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_hpricot_style # HACK move to test_divide in Page
    page = @agent.get("http://localhost/frame_test.html")

    link = (page/"//a[@class='bar']").first
    assert_not_nil(link)

    page = @agent.click(link)

    assert_equal("http://localhost/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_link_hpricot_style # HACK move to test_search in Page
    page = @agent.get("http://localhost/tc_encoded_links.html")

    page = @agent.click(page.search('a').first)

    assert_equal("http://localhost/form_post?a=b&b=c", page.uri.to_s)
  end

  def test_click_link_query
    page = @agent.get("http://localhost/tc_encoded_links.html")
    link = page.links.first
    assert_equal('/form_post?a=b&b=c', link.href)

    page = @agent.click(link)

    assert_equal("http://localhost/form_post?a=b&b=c", page.uri.to_s)
  end

  def test_click_link_space
    page = @agent.get("http://localhost/tc_bad_links.html")

    @agent.click page.links.first

    assert_match(/alt_text.html$/, @agent.history.last.uri.to_s)
    assert_equal(2, @agent.history.length)
  end

  def test_click_more
    @agent.get 'http://localhost/test_click.html'
    @agent.click 'A Button'
    assert_equal 'http://localhost/frame_test.html?words=nil',
      @agent.page.uri.to_s
    @agent.back
    @agent.click 'A Link'
    assert_equal 'http://localhost/index.html',
      @agent.page.uri.to_s
    @agent.back
    @agent.click @agent.page.link_with(:text => 'A Link')
    assert_equal 'http://localhost/index.html',
      @agent.page.uri.to_s
  end

  def test_connection_for_file
    uri = URI.parse 'file:///nonexistent'
    conn = @agent.connection_for uri

    assert_equal Mechanize::FileConnection.new, conn
  end

  def test_connection_for_http
    conn = @agent.connection_for @uri

    assert_equal @agent.http, conn
  end

  def test_delete_redirect
    page = @agent.delete('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  #def test_download
  #  Dir.mktmpdir do |dir|
  #    file = "#{dir}/download"
  #    open file, 'w' do |io|
  #      @agent.download 'http://example', io
  #    end

  #    assert_equal 1, File.stat(file).size
  #  end
  #end

  def test_enable_gzip
    @agent.enable_gzip @req

    assert_equal 'gzip,deflate,identity', @req['accept-encoding']
  end

  def test_enable_gzip_no
    @agent.gzip_enabled = false

    @agent.enable_gzip @req

    assert_equal 'identity', @req['accept-encoding']
  end

  def test_fetch_page_file_plus
    Tempfile.open '++plus++' do |io|
      content = 'plusses +++'
      io.write content
      io.rewind

      uri = URI.parse "file://#{Mechanize::Util.uri_escape io.path}"

      page = @agent.send :fetch_page, uri

      assert_equal content, page.body
      assert_kind_of Mechanize::File, page
    end
  end

  def test_fetch_page_file_space
    foo = File.expand_path("../htdocs/dir with spaces/foo.html", __FILE__)

    uri = URI.parse "file://#{Mechanize::Util.uri_escape foo}"

    page = @agent.send :fetch_page, uri

    assert_equal File.read(foo), page.body
    assert_kind_of Mechanize::Page, page
  end

  def test_fetch_page_file_nonexistent
    uri = URI.parse 'file:///nonexistent'

    e = assert_raises Mechanize::ResponseCodeError do
      @agent.send :fetch_page, uri
    end

    assert_equal '404 => Net::HTTPNotFound', e.message
  end

  def test_fetch_page_post_connect_hook
    response = nil
    @agent.post_connect_hooks << lambda { |_, res|
      response = res
    }

    @agent.get('http://localhost/')
    assert(response)
  end

  def test_get
    page = @agent.get('http://localhost', { :q => 'h' }, 'http://example',
                      { 'X-H' => 'v' })

    assert_equal 'http://localhost/?q=h', page.uri.to_s
  end

  def test_get_HTTP
    page = @agent.get('HTTP://localhost/', { :q => 'hello' })
    assert_equal('HTTP://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_anchor
    page = @agent.get('http://localhost/?foo=bar&#34;')
    assert_equal('http://localhost/?foo=bar%22', page.uri.to_s)
  end

  def test_get_bad_url
    assert_raise ArgumentError do
      @agent.get('/foo.html')
    end
  end

  def test_get_basic_auth_bad
    @agent.basic_auth('aaron', 'aaron')

    e = assert_raises Mechanize::ResponseCodeError do
      @agent.get("http://localhost/basic_auth")
    end

    assert_equal("401", e.response_code)
  end

  def test_get_basic_auth_none
    e = assert_raises Mechanize::ResponseCodeError do
      @agent.get("http://localhost/basic_auth")
    end

    assert_equal("401", e.response_code)
  end

  def test_get_digest_auth
    block_called = false

    @agent.basic_auth('user', 'pass')

    @agent.pre_connect_hooks << lambda { |_, request|
      block_called = true
      request.to_hash.each do |k,v|
        assert_equal(1, v.length)
      end
    }

    page = @agent.get("http://localhost/digest_auth")
    assert_equal('You are authenticated', page.body)
    assert block_called
  end

  def test_get_file
    page = @agent.get("http://localhost/frame_test.html")
    content_length = page.header['Content-Length']
    page_as_string = @agent.get_file("http://localhost/frame_test.html")
    assert_equal(content_length.to_i, page_as_string.length.to_i)
  end

  def test_get_follow_meta_refresh
    @agent.follow_meta_refresh = true

    page = @agent.get('http://localhost/tc_follow_meta.html')

    assert_equal(2, @agent.history.length)

    assert_equal('http://localhost/tc_follow_meta.html',
                 @agent.history.first.uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @agent.history.last.uri.to_s)
  end

  def test_get_follow_meta_refresh_anywhere
    @agent.follow_meta_refresh = :anywhere
    requests = []
    @agent.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @agent.get('http://localhost/tc_meta_in_body.html')
    assert_equal 2, requests.length
  end

  def test_get_follow_meta_refresh_disabled
    page = @agent.get('http://localhost/tc_follow_meta.html')
    assert_equal('http://localhost/tc_follow_meta.html', page.uri.to_s)
    assert_equal(1, page.meta_refresh.length)
  end

  def test_get_follow_meta_refresh_empty_url
    @agent.follow_meta_refresh = true

    page = @agent.get('http://localhost/refresh_with_empty_url')

    assert_equal(3, @agent.history.length)
    assert_equal('http://localhost/refresh_with_empty_url',
                 @agent.history[0].uri.to_s)
    assert_equal('http://localhost/refresh_with_empty_url',
                 @agent.history[1].uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @agent.history.last.uri.to_s)
  end

  def test_get_follow_meta_refresh_in_body
    @agent.follow_meta_refresh = true
    requests = []
    @agent.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @agent.get('http://localhost/tc_meta_in_body.html')
    assert_equal 1, requests.length
  end

  def test_get_follow_meta_refresh_no_url
    @agent.follow_meta_refresh = true

    page = @agent.get('http://localhost/refresh_without_url')

    assert_equal(3, @agent.history.length)
    assert_equal('http://localhost/refresh_without_url',
                 @agent.history[0].uri.to_s)
    assert_equal('http://localhost/refresh_without_url',
                 @agent.history[1].uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @agent.history.last.uri.to_s)
  end

  def test_get_follow_meta_refresh_referer_not_sent
    @agent.follow_meta_refresh = true

    requests = []

    @agent.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @agent.get('http://localhost/tc_follow_meta.html')

    assert_equal 2, @agent.history.length
    assert_nil requests.last['referer']
  end

  def test_get_gzip
    page = @agent.get("http://localhost/gzip?file=index.html")

    assert_kind_of(Mechanize::Page, page)

    assert_match('Hello World', page.body)
  end

  def test_get_http_refresh
    @agent.follow_meta_refresh = true
    page = @agent.get('http://localhost/http_refresh?refresh_time=0')
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal(2, @agent.history.length)
  end

  def test_get_http_refresh_delay
    @agent.follow_meta_refresh = true
    class << @agent
      attr_accessor :slept
      def sleep *args
        @slept = args
      end
    end

    @agent.get('http://localhost/http_refresh?refresh_time=1')
    assert_equal [1], @agent.slept
  end

  def test_get_http_refresh_disabled
    page = @agent.get('http://localhost/http_refresh?refresh_time=0')
    assert_equal('http://localhost/http_refresh?refresh_time=0', page.uri.to_s)
  end

  def test_get_kcode
    $KCODE = 'u'
    page = @agent.get("http://localhost/?a=#{[0xd6].pack('U')}")
    assert_not_nil(page)
    assert_equal('http://localhost/?a=%D6', page.uri.to_s)
    $KCODE = 'NONE'
  end unless RUBY_VERSION >= '1.9.0'

  def test_get_query
    page = @agent.get('http://localhost/', { :q => 'hello' })
    assert_equal('http://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_redirect
    page = @agent.get('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_get_redirect_found
    page = @agent.get('http://localhost/response_code?code=302&ct=test/xml')

    assert_equal('http://localhost/index.html', page.uri.to_s)

    assert_equal(2, @agent.history.length)
  end

  def test_get_redirect_infinite
    assert_raises(Mechanize::RedirectLimitReachedError) {
      @agent.get('http://localhost/infinite_refresh')
    }
  end

  def test_get_referer
    request = nil
    @agent.pre_connect_hooks << lambda { |_, req|
      request = req
    }

    @agent.get('http://localhost/', [], 'http://tenderlovemaking.com/')
    assert_equal 'http://tenderlovemaking.com/', request['Referer']
  end

  def test_get_referer_file
    assert_nothing_raised do
      @agent.get('http://localhost', [], Mechanize::File.new(URI.parse('http://tenderlovemaking.com/crossdomain.xml')))
    end

    # HACK no assertion of behavior
  end

  def test_get_referer_none
    requests = []
    @agent.pre_connect_hooks << lambda { |_, request|
      requests << request
    }

    @agent.get('http://localhost/')
    @agent.get('http://localhost/')
    assert_equal(2, requests.length)
    requests.each do |request|
      assert_nil request['referer']
    end
  end

  def test_get_scheme_unsupported
    assert_raise(Mechanize::UnsupportedSchemeError) {
      @agent.get('ftp://server.com/foo.html')
    }
  end

  def test_get_space
    page = nil

    page = @agent.get("http://localhost/tc_bad_links.html ")

    assert_match(/tc_bad_links.html$/, @agent.history.last.uri.to_s)

    assert_equal(1, @agent.history.length)
  end

  def test_get_tilde
    page = @agent.get('http://localhost/?foo=~2')
    assert_equal('http://localhost/?foo=~2', page.uri.to_s)
  end

  def test_get_weird
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

  def test_get_yield
    pages = nil

    @agent.get("http://localhost/file_upload.html") { |page|
      pages = page
    }

    assert pages
    assert_equal('File Upload Form', pages.title)
  end

  def test_head_redirect
    page = @agent.head('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'HEAD', page.header['X-Request-Method']
  end

  def test_history
    0.upto(25) do |i|
      assert_equal(i, @agent.history.size)
      @agent.get("http://localhost/")
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

  def test_history_order
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

  def test_html_parser_equals
    @agent.html_parser = {}
    assert_raises(NoMethodError) {
      @agent.get('http://localhost/?foo=~2').links
    }
  end

  def test_http_request_file
    uri = URI.parse 'file:///nonexistent'
    request = @agent.http_request uri, :get

    assert_kind_of Mechanize::FileRequest, request
    assert_equal '/nonexistent', request.path
  end

  def test_http_request_get
    request = @agent.http_request @uri, :get

    assert_kind_of Net::HTTP::Get, request
    assert_equal '/', request.path
  end

  def test_http_request_post
    request = @agent.http_request @uri, :post

    assert_kind_of Net::HTTP::Post, request
    assert_equal '/', request.path
  end

  def test_max_history_equals
    @agent.max_history = 10
    0.upto(10) do |i|
      assert_equal(i, @agent.history.size)
      @agent.get("http://localhost/")
    end

    0.upto(10) do |i|
      assert_equal(10, @agent.history.size)
      @agent.get("http://localhost/")
    end
  end

  def test_post_basic_auth
    class << @agent
      alias :old_fetch_page :fetch_page
      attr_accessor :requests
      def fetch_page(uri, method, *args)
        @requests ||= []
        x = old_fetch_page(uri, method, *args)
        @requests << method
        x
      end
    end
    @agent.basic_auth('user', 'pass')
    page = @agent.post("http://localhost/basic_auth")
    assert_equal('You are authenticated', page.body)
    assert_equal(2, @agent.requests.length)
    r1 = @agent.requests[0]
    r2 = @agent.requests[1]
    assert_equal(r1, r2)
  end

  def test_post_redirect
    page = @agent.post('http://localhost/redirect')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_post_connect
    @agent.post_connect_hooks << proc { |agent, response|
      assert_equal @agent, agent
      assert_kind_of Net::HTTPResponse, response
      throw :called
    }

    assert_throws :called do
      @agent.post_connect @res
    end
  end

  def test_pre_connect
    @agent.pre_connect_hooks << proc { |agent, request|
      assert_equal @agent, agent
      assert_kind_of Net::HTTPRequest, request
      throw :called
    }

    assert_throws :called do
      @agent.pre_connect @req
    end
  end

  def test_put_redirect
    page = @agent.put('http://localhost/redirect', 'foo')

    assert_equal(page.uri.to_s, 'http://localhost/verb')

    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_request_cookies
    uri = URI.parse 'http://host.example.com'
    Mechanize::Cookie.parse uri, 'hello=world domain=.example.com' do |cookie|
      @agent.cookie_jar.add uri, cookie
    end

    @agent.request_cookies @req, uri

    assert_equal 'hello=world domain=.example.com', @req['Cookie']
  end

  def test_request_cookies_none
    @agent.request_cookies @req, @uri

    assert_nil @req['Cookie']
  end

  def test_request_cookies_many
    uri = URI.parse 'http://host.example.com'
    cookie_str = 'a=b domain=.example.com, c=d domain=.example.com'
    Mechanize::Cookie.parse uri, cookie_str do |cookie|
      @agent.cookie_jar.add uri, cookie
    end

    @agent.request_cookies @req, uri

    expected = cookie_str.sub ', ', '; '

    assert_equal expected, @req['Cookie']
  end

  def test_request_cookies_wrong_domain
    uri = URI.parse 'http://host.example.com'
    Mechanize::Cookie.parse uri, 'hello=world domain=.example.com' do |cookie|
      @agent.cookie_jar.add uri, cookie
    end

    @agent.request_cookies @req, @uri

    assert_nil @req['Cookie']
  end

  def test_request_host
    @agent.request_host @req, @uri

    assert_equal 'example', @req['host']
  end

  def test_request_host_nonstandard
    @uri.port = 81

    @agent.request_host @req, @uri

    assert_equal 'example:81', @req['host']
  end

  def test_request_language_charset
    @agent.request_language_charset @req

    assert_equal 'en-us,en;q=0.5', @req['accept-language']
    assert_equal 'ISO-8859-1,utf-8;q=0.7,*;q=0.7', @req['accept-charset']
  end

  def test_request_add_headers
    @agent.request_add_headers @req, 'Content-Length' => 300

    assert_equal '300', @req['content-length']
  end

  def test_request_add_headers_etag
    @agent.request_add_headers @req, :etag => '300'

    assert_equal '300', @req['etag']
  end

  def test_request_add_headers_if_modified_since
    @agent.request_add_headers @req, :if_modified_since => 'some_date'

    assert_equal 'some_date', @req['if-modified-since']
  end

  def test_request_add_headers_none
    @agent.request_add_headers @req

    assert_equal @headers, @req.to_hash.keys.sort
  end

  def test_request_add_headers_request_headers
    @agent.request_headers['X-Foo'] = 'bar'

    @agent.request_add_headers @req

    assert_equal @headers + %w[x-foo], @req.to_hash.keys.sort
  end

  def test_request_add_headers_symbol
    e = assert_raises ArgumentError do
      @agent.request_add_headers @req, :content_length => 300
    end

    assert_equal 'unknown header symbol content_length', e.message
  end

  def test_request_referer
    referer = URI.parse 'http://old.example'

    @agent.request_referer @req, @uri, referer

    assert_equal 'http://old.example', @req['referer']
  end

  def test_request_referer_https
    uri = URI.parse 'https://example'
    referer = URI.parse 'https://old.example'

    @agent.request_referer @req, uri, referer

    assert_equal 'https://old.example', @req['referer']
  end

  def test_request_referer_https_downgrade
    referer = URI.parse 'https://old.example'

    @agent.request_referer @req, @uri, referer

    assert_nil @req['referer']
  end

  def test_request_referer_https_downgrade_case
    uri = URI.parse 'http://example'
    referer = URI.parse 'httpS://old.example'

    @agent.request_referer @req, uri, referer

    assert_nil @req['referer']
  end

  def test_request_referer_none
    @agent.request_referer @req, @uri, nil

    assert_nil @req['referer']
  end

  def test_request_user_agent
    @agent.request_user_agent @req

    assert_match %r%^Mechanize/#{Mechanize::VERSION}%, @req['user-agent']

    ruby_version = if RUBY_PATCHLEVEL >= 0 then
                     "#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
                   else
                     "#{RUBY_VERSION}dev#{RUBY_REVISION}"
                   end

    assert_match %r%Ruby/#{ruby_version}%, @req['user-agent']
  end

  def test_resolve_bad_uri
    e = assert_raises ArgumentError do
      @agent.resolve 'google'
    end

    assert_equal 'absolute URL needed (not google)', e.message
  end

  def test_resolve_utf8
    uri = 'http://example?q=ü'

    resolved = @agent.resolve uri

    assert_equal '/?q=%C3%BC', resolved.request_uri
  end

  def test_resolve_parameters_body
    input_params = { :q => 'hello' }

    uri, params = @agent.resolve_parameters @uri, :post, input_params

    assert_equal 'http://example/', uri.to_s
    assert_equal input_params, params
  end

  def test_resolve_parameters_query
    uri, params = @agent.resolve_parameters @uri, :get, :q => 'hello'

    assert_equal 'http://example/?q=hello', uri.to_s
    assert_nil params
  end

  def test_resolve_parameters_query_append
    input_params = { :q => 'hello' }
    @uri.query = 'a=b'

    uri, params = @agent.resolve_parameters @uri, :get, input_params

    assert_equal 'http://example/?a=b&q=hello', uri.to_s
    assert_nil params
  end

  def test_response_content_encoding_7_bit
    def @res.content_length() 4 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[7bit]

    body = @agent.response_content_encoding @res, StringIO.new('part')

    assert_equal 'part', body
  end

  def test_response_content_encoding_deflate
    def @res.content_length() 12 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[deflate]
    body_io = StringIO.new "x\x9C+H,*\x01\x00\x04?\x01\xB8"

    body = @agent.response_content_encoding @res, body_io

    assert_equal 'part', body
  end

  def test_response_content_encoding_deflate_chunked
    def @res.content_length() nil end
    @res.instance_variable_set :@header, 'content-encoding' => %w[deflate]
    body_io = StringIO.new "x\x9C+H,*\x01\x00\x04?\x01\xB8"

    body = @agent.response_content_encoding @res, body_io

    assert_equal 'part', body
  end

  # IIS/6.0 ASP.NET/2.0.50727 does not wrap deflate with zlib, WTF?
  def test_response_content_encoding_deflate_no_zlib
    def @res.content_length() 6 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[deflate]

    body = @agent.response_content_encoding @res, StringIO.new("+H,*\001\000")

    assert_equal 'part', body
  end

  def test_response_content_encoding_gzip
    def @res.content_length() 24 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[gzip]
    body_io = StringIO.new \
      "\037\213\b\0002\002\225M\000\003+H,*\001\000\306p\017I\004\000\000\000"

    body = @agent.response_content_encoding @res, body_io

    assert_equal 'part', body
  end

  def test_response_content_encoding_gzip_chunked
    def @res.content_length() nil end
    @res.instance_variable_set :@header, 'content-encoding' => %w[gzip]
    body_io = StringIO.new \
      "\037\213\b\0002\002\225M\000\003+H,*\001\000\306p\017I\004\000\000\000"

    body = @agent.response_content_encoding @res, body_io

    assert_equal 'part', body
  end

  def test_response_content_encoding_none
    def @res.content_length() 4 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[none]

    body = @agent.response_content_encoding @res, StringIO.new('part')

    assert_equal 'part', body
  end

  def test_response_content_encoding_x_gzip
    def @res.content_length() 24 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[x-gzip]
    body_io = StringIO.new \
      "\037\213\b\0002\002\225M\000\003+H,*\001\000\306p\017I\004\000\000\000"

    body = @agent.response_content_encoding @res, body_io

    assert_equal 'part', body
  end

  def test_response_content_encoding_unknown
    def @res.content_length() 4 end
    @res.instance_variable_set :@header, 'content-encoding' => %w[unknown]
    body = StringIO.new 'part'

    e = assert_raises Mechanize::Error do
      @agent.response_content_encoding @res, body
    end

    assert_equal 'Unsupported Content-Encoding: unknown', e.message
  end

  def test_response_cookies
    uri = URI.parse 'http://host.example.com'
    cookie_str = 'a=b domain=.example.com'
    @res.instance_variable_set(:@header,
                               'set-cookie' => [cookie_str],
                               'content-type' => %w[text/html])
    page = Mechanize::Page.new uri, @res, '', 200, @agent

    @agent.response_cookies @res, uri, page

    assert_equal ['a=b domain=.example.com'],
                 @agent.cookie_jar.cookies(uri).map { |c| c.to_s }
  end

  def test_response_cookies_meta
    uri = URI.parse 'http://host.example.com'
    cookie_str = 'a=b domain=.example.com'

    body = <<-BODY
<head>
  <meta http-equiv="Set-Cookie" content="#{cookie_str}">
</head>"
    BODY

    @res.instance_variable_set(:@header,
                               'content-type' => %w[text/html])
    page = Mechanize::Page.new uri, @res, body, 200, @agent

    @agent.response_cookies @res, uri, page

    assert_equal ['a=b domain=.example.com'],
                 @agent.cookie_jar.cookies(uri).map { |c| c.to_s }
  end

  def test_response_follow_meta_refresh
    uri = URI.parse 'http://example/#id+1'

    body = <<-BODY
<title></title>
<meta http-equiv="refresh" content="0">
    BODY

    page = Mechanize::Page.new(uri, {'content-type' => 'text/html'}, body,
                               200, @agent)

    @agent.follow_meta_refresh = true

    page = @agent.response_follow_meta_refresh @res, uri, page, 0

    assert_equal uri, page.uri
  end

  def test_response_read
    def @res.read_body() yield 'part' end
    def @res.content_length() 4 end

    io = @agent.response_read @res, @req

    body = io.read

    assert_equal 'part', body
    assert_equal Encoding::BINARY, body.encoding if body.respond_to? :encoding
  end

  def test_response_read_content_length_head
    req = Net::HTTP::Head.new '/'

    def @res.content_length() end
    def @res.read_body() end

    io = @agent.response_read @res, req

    assert_equal '', io.read
  end

  def test_response_read_content_length_mismatch
    def @res.content_length() 5 end
    def @res.read_body() yield 'part' end

    e = assert_raises EOFError do
      @agent.response_read @res, @req
    end

    assert_equal 'Content-Length (5) does not match response body length (4)',
                 e.message
  end

  def test_response_read_content_length_redirect
    res = Net::HTTPFound.allocate
    def res.content_length() 5 end
    def res.code() 302 end
    def res.read_body() yield 'part' end
    res.instance_variable_set :@header, {}

    io = @agent.response_read res, @req

    assert_equal 'part', io.read
  end

  def test_response_read_error
    def @res.read_body()
      yield 'part'
      raise Net::HTTP::Persistent::Error
    end

    e = assert_raises Mechanize::ResponseReadError do
      @agent.response_read @res, @req
    end

    assert_equal @res, e.response
    assert_equal 'part', e.body_io.read
    assert_kind_of Net::HTTP::Persistent::Error, e.error
  end

  def test_response_read_file
    Tempfile.open 'pi.txt' do |tempfile|
      tempfile.write "π\n"
      tempfile.flush
      tempfile.rewind

      uri = URI.parse "file://#{tempfile.path}"
      req = Mechanize::FileRequest.new uri
      res = Mechanize::FileResponse.new tempfile.path

      io = @agent.response_read res, req

      expected = "π\n"
      expected.force_encoding Encoding::BINARY if expected.respond_to? :encoding

      body = io.read
      assert_equal expected, body
      assert_equal Encoding::BINARY, body.encoding if body.respond_to? :encoding
    end
  end

  def test_response_read_no_body
    req = Net::HTTP::Options.new '/'

    def @res.content_length() end
    def @res.read_body() end

    io = @agent.response_read @res, req

    assert_equal '', io.read
  end

  def test_response_read_unknown_code
    res = Net::HTTPUnknownResponse.allocate
    res.instance_variable_set :@code, 9999
    def res.read_body() yield 'part' end

    e = assert_raises Mechanize::ResponseCodeError do
      @agent.response_read res, @req
    end

    assert_equal res, e.page
  end

  def test_response_parse
    body = '<title>hi</title>'
    @res.instance_variable_set :@header, 'content-type' => %w[text/html]

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page
    assert_equal @agent, page.mech
  end

  def test_response_parse_content_type_case
    body = '<title>hi</title>'
    @res.instance_variable_set(:@header, 'content-type' => %w[text/HTML])

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page

    assert_equal 'text/HTML', page.content_type
  end

  def test_response_parse_content_type_encoding
    body = '<title>hi</title>'
    @res.instance_variable_set(:@header,
                               'content-type' =>
                                 %w[text/html;charset=ISO-8859-1])

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page
    assert_equal @agent, page.mech

    assert_equal 'ISO-8859-1', page.encoding
    assert_equal 'ISO-8859-1', page.parser.encoding
  end

  def test_response_parse_content_type_encoding_garbage
    body = '<title>hi</title>'
    @res.instance_variable_set(:@header,
                               'content-type' =>
                                 %w[text/html; charset=garbage_charset])

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page
    assert_equal @agent, page.mech
  end

  def test_response_parse_content_type_encoding_broken_iso_8859_1
    body = '<title>hi</title>'
    @res.instance_variable_set(:@header,
                               'content-type' =>
                                 %w[text/html; charset=ISO_8859-1])

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page
    assert_equal 'ISO_8859-1', page.encoding
  end

  def test_response_parse_content_type_encoding_broken_utf_8
    body = '<title>hi</title>'
    @res.instance_variable_set(:@header,
                               'content-type' =>
                                 %w[text/html; charset=UTF8])

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page
    assert_equal 'UTF8', page.encoding
    assert_equal 'UTF8', page.parser.encoding
  end

  def test_response_parse_content_type_encoding_semicolon
    body = '<title>hi</title>'
    @res.instance_variable_set(:@header,
                               'content-type' =>
                                 %w[text/html;charset=UTF-8;])

    page = @agent.response_parse @res, body, @uri

    assert_instance_of Mechanize::Page, page

    assert_equal 'UTF-8', page.encoding
  end

  def test_set_proxy
    @agent.set_proxy('www.example.com', 9001, 'joe', 'lol')

    assert_equal(@agent.http.proxy_uri.host,     'www.example.com')
    assert_equal(@agent.http.proxy_uri.port,     9001)
    assert_equal(@agent.http.proxy_uri.user,     'joe')
    assert_equal(@agent.http.proxy_uri.password, 'lol')
  end

  def test_submit_bad_form_method
    page = @agent.get("http://localhost/bad_form_test.html")
    assert_raise ArgumentError do
      @agent.submit(page.forms.first)
    end
  end

  def test_submit_check_one
    page = @agent.get('http://localhost/tc_checkboxes.html')
    form = page.forms.first
    form.checkboxes_with(:name => 'green')[1].check

    page = @agent.submit(form)

    assert_equal(1, page.links.length)
    assert_equal('green:on', page.links.first.text)
  end

  def test_submit_check_two
    page = @agent.get('http://localhost/tc_checkboxes.html')
    form = page.forms.first
    form.checkboxes_with(:name => 'green')[0].check
    form.checkboxes_with(:name => 'green')[1].check

    page = @agent.submit(form)

    assert_equal(2, page.links.length)
    assert_equal('green:on', page.links[0].text)
    assert_equal('green:on', page.links[1].text)
  end

  def test_submit_headers
    page = @agent.get('http://localhost:2000/form_no_action.html')
    assert form = page.forms.first
    form.action = '/http_headers'
    page = @agent.submit(form, nil, { 'foo' => 'bar' })
    headers = Hash[*(
      page.body.split("\n").map { |x| x.split('|') }.flatten
    )]
    assert_equal 'bar', headers['foo']
  end

  def test_submit_too_many_radiobuttons
    page = @agent.get("http://localhost/form_test.html")
    form = page.form_with(:name => 'post_form1')
    form.radiobuttons.each { |r| r.checked = true }

    assert_raises Mechanize::Error do
      @agent.submit(form)
    end
  end

  def test_transact
    @agent.get("http://localhost/frame_test.html")
    assert_equal(1, @agent.history.length)
    @agent.transact { |a|
      5.times {
        @agent.get("http://localhost/frame_test.html")
      }
      assert_equal(6, @agent.history.length)
    }
    assert_equal(1, @agent.history.length)
  end

  def test_user_agent_alias_equals_unknown
    assert_raises ArgumentError do
      @agent.user_agent_alias = "Aaron's Browser"
    end
  end

  def test_visited_eh
    @agent.get("http://localhost/content_type_test?ct=application/pdf")
    assert_equal(true,
      @agent.visited?("http://localhost/content_type_test?ct=application/pdf"))
    assert_equal(false,
      @agent.visited?("http://localhost/content_type_test"))
    assert_equal(false,
      @agent.visited?("http://localhost/content_type_test?ct=text/html"))
  end

  def test_visited_eh_redirect
    @agent.get("http://localhost/response_code?code=302")
    assert_equal("http://localhost/index.html",
      @agent.current_page.uri.to_s)
    assert_equal(true,
                 @agent.visited?('http://localhost/response_code?code=302'))
  end

  def assert_header(page, header)
    headers = {}

    page.body.split(/[\r\n]+/).each do |page_header|
      headers.[]=(*page_header.chomp.split(/\|/))
    end

    header.each do |key, value|
      assert(headers.has_key?(key))
      assert_equal(value, headers[key])
    end
  end
end

