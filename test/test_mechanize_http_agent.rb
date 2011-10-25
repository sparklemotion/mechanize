# coding: utf-8
require 'helper'

class TestMechanizeHttpAgent < MiniTest::Unit::TestCase

  def setup
    @mech = Mechanize.new
    @agent = @mech.agent

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

  def test_connection_for_file
    uri = URI.parse 'file:///nonexistent'
    conn = @agent.connection_for uri

    assert_equal Mechanize::FileConnection.new, conn
  end

  def test_connection_for_http
    conn = @agent.connection_for @uri

    assert_equal @agent.http, conn
  end

  def test_enable_gzip
    @agent.enable_gzip @req

    assert_equal 'gzip,deflate,identity', @req['accept-encoding']
  end

  def test_enable_gzip_no
    @agent.gzip_enabled = false

    @agent.enable_gzip @req

    assert_equal 'identity', @req['accept-encoding']
  end

  def test_fetch_file_plus
    Tempfile.open '++plus++' do |io|
      content = 'plusses +++'
      io.write content
      io.rewind

      uri = URI.parse "file://#{Mechanize::Util.uri_escape io.path}"

      page = @agent.fetch uri

      assert_equal content, page.body
      assert_kind_of Mechanize::File, page
    end
  end

  def test_fetch_file_space
    foo = File.expand_path("../htdocs/dir with spaces/foo.html", __FILE__)

    uri = URI.parse "file://#{Mechanize::Util.uri_escape foo}"

    page = @agent.fetch uri

    assert_equal File.read(foo), page.body
    assert_kind_of Mechanize::Page, page
  end

  def test_fetch_file_nonexistent
    uri = URI.parse 'file:///nonexistent'

    e = assert_raises Mechanize::ResponseCodeError do
      @agent.fetch uri
    end

    assert_equal '404 => Net::HTTPNotFound', e.message
  end

  def test_fetch_post_connect_hook
    response = nil
    @agent.post_connect_hooks << lambda { |_, _, res, _| response = res }

    @agent.fetch 'http://localhost/'

    assert response
  end

  def test_get_robots
    robotstxt = @agent.get_robots 'http://localhost/robots.txt'
    refute_equal '', robotstxt

    robotstxt = @agent.get_robots 'http://localhost/response_code?code=404'
    assert_equal '', robotstxt
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

  def test_post_connect
    @agent.post_connect_hooks << proc { |agent, uri, response, body|
      assert_equal @agent, agent
      assert_equal @res, response
      assert_equal 'body', body
      throw :called
    }

    assert_throws :called do
      @agent.post_connect @uri, @res, 'body'
    end
  end

  def test_pre_connect
    @agent.pre_connect_hooks << proc { |agent, request|
      assert_equal @agent, agent
      assert_equal @req, request
      throw :called
    }

    assert_throws :called do
      @agent.pre_connect @req
    end
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

  def test_get_meta_refresh_header_follow_self
    @agent.follow_meta_refresh = true
    @agent.follow_meta_refresh_self = true

    page = Mechanize::Page.new(@uri, {'content-type' => 'text/html'}, '',
                               200, @mech)
    @res.instance_variable_set :@header, 'refresh' => ['0']

    refresh = @agent.get_meta_refresh @res, @uri, page

    assert_equal [0.0, URI('http://example/')], refresh
  end

  def test_get_meta_refresh_header_no_follow
    page = Mechanize::Page.new(@uri, {'content-type' => 'text/html'}, '',
                               200, @mech)
    @res.instance_variable_set :@header, 'refresh' => ['0']

    refresh = @agent.get_meta_refresh @res, @uri, page

    assert_nil refresh
  end

  def test_get_meta_refresh_header_no_follow_self
    @agent.follow_meta_refresh = true

    page = Mechanize::Page.new(@uri, {'content-type' => 'text/html'}, '',
                               200, @mech)
    @res.instance_variable_set :@header, 'refresh' => ['0']

    refresh = @agent.get_meta_refresh @res, @uri, page

    assert_nil refresh
  end

  def test_get_meta_refresh_meta_follow_self
    @agent.follow_meta_refresh = true
    @agent.follow_meta_refresh_self = true

    body = <<-BODY
<title></title>
<meta http-equiv="refresh" content="0">
    BODY

    page = Mechanize::Page.new(@uri, {'content-type' => 'text/html'}, body,
                               200, @mech)

    refresh = @agent.get_meta_refresh @res, @uri, page

    assert_equal [0, 'http://example/'], refresh
  end

  def test_get_meta_refresh_meta_no_follow
    body = <<-BODY
<title></title>
<meta http-equiv="refresh" content="0">
    BODY

    page = Mechanize::Page.new(@uri, {'content-type' => 'text/html'}, body,
                               200, @mech)

    refresh = @agent.get_meta_refresh @res, @uri, page

    assert_nil refresh
  end

  def test_get_meta_refresh_meta_no_follow_self
    @agent.follow_meta_refresh = true

    body = <<-BODY
<title></title>
<meta http-equiv="refresh" content="0">
    BODY

    page = Mechanize::Page.new(@uri, {'content-type' => 'text/html'}, body,
                               200, @mech)

    refresh = @agent.get_meta_refresh @res, @uri, page

    assert_nil refresh
  end

  def test_hook_content_encoding_response
    @mech.content_encoding_hooks << lambda{|agent, uri, response, response_body_io|
      response['content-encoding'] = 'gzip' if response['content-encoding'] == 'agzip'}

    @res.instance_variable_set :@header, 'content-encoding' => %w[agzip]
    body_io = StringIO.new 'part'
    @agent.hook_content_encoding @res, @uri, body_io

    assert_equal 'gzip', @res['content-encoding']
  end

  def test_response_cookies
    uri = URI.parse 'http://host.example.com'
    cookie_str = 'a=b domain=.example.com'
    @res.instance_variable_set(:@header,
                               'set-cookie' => [cookie_str],
                               'content-type' => %w[text/html])
    page = Mechanize::Page.new uri, @res, '', 200, @mech

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
    page = Mechanize::Page.new uri, @res, body, 200, @mech

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
                               200, @mech)

    @agent.follow_meta_refresh = true
    @agent.follow_meta_refresh_self = true

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
    assert_equal @mech, page.mech
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
    assert_equal @mech, page.mech

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
    assert_equal @mech, page.mech
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

  def test_set_http
    @agent.idle_timeout = 1
    @agent.set_http

    assert_equal 'mechanize', @agent.http.name
    assert_equal 1, @agent.http.idle_timeout
  end

  def test_set_proxy
    @agent.set_proxy('www.example.com', 9001, 'joe', 'lol')

    assert_equal(@agent.proxy_uri.host,     'www.example.com')
    assert_equal(@agent.proxy_uri.port,     9001)
    assert_equal(@agent.proxy_uri.user,     'joe')
    assert_equal(@agent.proxy_uri.password, 'lol')
  end

end

