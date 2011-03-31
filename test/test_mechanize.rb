require 'helper'

class TestMechanize < Test::Unit::TestCase

  def setup
    @agent = Mechanize.new
    @uri = URI.parse 'http://example/'
    @req = Net::HTTP::Get.new '/'
  end

  def test_connection_for_file
    uri = URI.parse 'file:///nonexistent'
    conn = @agent.connection_for uri

    assert_instance_of Object, conn
    assert_respond_to conn, :request
  end

  def test_connection_for_http
    conn = @agent.connection_for @uri

    assert_equal @agent.http, conn
  end

  def test_enable_gzip
    @agent.enable_gzip @req

    assert_equal 'gzip,identity', @req['accept-encoding']
  end

  def test_enable_gzip_no
    @agent.gzip_enabled = false

    @agent.enable_gzip @req

    assert_equal 'identity', @req['accept-encoding']
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

  def test_request_cookies
    uri = URI.parse 'http://host.example.com'
    Mechanize::Cookie.parse uri, 'hello=world domain=.example.com' do |cookie|
      @agent.cookie_jar.add uri, cookie
    end

    @agent.request_cookies uri, @req

    assert_equal 'hello=world domain=.example.com', @req['Cookie']
  end

  def test_request_cookies_none
    @agent.request_cookies @uri, @req

    assert_nil @req['Cookie']
  end

  def test_request_cookies
    uri = URI.parse 'http://host.example.com'
    cookie_str = 'a=b domain=.example.com, c=d domain=.example.com'
    Mechanize::Cookie.parse uri, cookie_str do |cookie|
      @agent.cookie_jar.add uri, cookie
    end

    @agent.request_cookies uri, @req

    expected = cookie_str.sub ', ', '; '

    assert_equal expected, @req['Cookie']
  end

  def test_request_cookies_wrong_domain
    uri = URI.parse 'http://host.example.com'
    Mechanize::Cookie.parse uri, 'hello=world domain=.example.com' do |cookie|
      @agent.cookie_jar.add uri, cookie
    end

    @agent.request_cookies @uri, @req

    assert_nil @req['Cookie']
  end

  def test_request_host
    @agent.request_host @uri, @req

    assert_equal 'example', @req['host']
  end

  def test_request_host_nonstandard
    @uri.port = 81

    @agent.request_host @uri, @req

    assert_equal 'example:81', @req['host']
  end

  def test_request_language_charset
    @agent.request_language_charset @req

    assert_equal 'en-us,en;q=0.5', @req['accept-language']
    assert_equal 'ISO-8859-1,utf-8;q=0.7,*;q=0.7', @req['accept-charset']
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

  def test_request_custom_headers
    @agent.request_headers['X-Foo'] = 'bar'

    @agent.request_custom_headers @req

    assert_equal %w[accept user-agent x-foo], @req.to_hash.keys.sort
  end

  def test_request_custom_headers_none
    @agent.request_custom_headers @req

    assert_equal %w[accept user-agent], @req.to_hash.keys.sort
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

  def test_request_referer_none
    @agent.request_referer @req, @uri, nil

    assert_nil @req['referer']
  end

  def test_request_user_agent
    @agent.request_user_agent @req

    assert_match %r%^WWW-Mechanize%, @req['user-agent']
  end

end

