require 'mechanize'
require 'logger'
require 'tempfile'
require 'tmpdir'
require 'webrick'
require 'zlib'

require 'rubygems'

begin
  gem 'minitest'
rescue Gem::LoadError
end

require 'minitest/autorun'

class Mechanize::TestCase < MiniTest::Unit::TestCase

  TEST_DIR = File.expand_path '../../../test', __FILE__
  REQUESTS = []

  def setup
    super

    REQUESTS.clear
    @mech = Mechanize.new
    @ssl_private_key = nil
    @ssl_certificate = nil
  end

  def fake_page agent = @mech
    uri = URI 'http://fake.example/'
    html = <<-END
<html>
<body>
<form><input type="submit" value="submit" /></form>
</body>
</html>
    END

    response = { 'content-type' => 'text/html' }

    Mechanize::Page.new uri, response, html, 200, agent
  end

  def have_encoding?
    Object.const_defined? :Encoding
  end

  def html_page body
    uri = URI 'http://example/'
    Mechanize::Page.new uri, { 'content-type' => 'text/html' }, body, 200, @mech
  end

  def in_tmpdir
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        yield
      end
    end
  end

  def node element, attributes = {}
    doc = Nokogiri::HTML::Document.new

    node = Nokogiri::XML::Node.new element, doc

    attributes.each do |name, value|
      node[name] = value
    end

    node
  end

  def page uri, content_type = 'text/html', body = '', code = 200
    uri = URI uri unless URI::Generic === uri

    Mechanize::Page.new(uri, { 'content-type' => content_type }, body, code,
                        @mech)
  end

  def requests
    REQUESTS
  end

  def ssl_private_key
    @ssl_private_key ||= OpenSSL::PKey::RSA.new <<-KEY
-----BEGIN RSA PRIVATE KEY-----
MIG7AgEAAkEA8pmEfmP0Ibir91x6pbts4JmmsVZd3xvD5p347EFvBCbhBW1nv1Gs
bCBEFlSiT1q2qvxGb5IlbrfdhdgyqdTXUQIBAQIBAQIhAPumXslvf6YasXa1hni3
p80joKOug2UUgqOLD2GUSO//AiEA9ssY6AFxjHWuwo/+/rkLmkfO2s1Lz3OeUEWq
6DiHOK8CAQECAQECIQDt8bc4vS6wh9VXApNSKIpVygtxSFe/IwLeX26n77j6Qg==
-----END RSA PRIVATE KEY-----
    KEY
  end

  def ssl_certificate
    @ssl_certificate ||= OpenSSL::X509::Certificate.new <<-CERT
-----BEGIN CERTIFICATE-----
MIIBQjCB7aADAgECAgEAMA0GCSqGSIb3DQEBBQUAMCoxDzANBgNVBAMMBm5vYm9k
eTEXMBUGCgmSJomT8ixkARkWB2V4YW1wbGUwIBcNMTExMTAzMjEwODU5WhgPOTk5
OTEyMzExMjU5NTlaMCoxDzANBgNVBAMMBm5vYm9keTEXMBUGCgmSJomT8ixkARkW
B2V4YW1wbGUwWjANBgkqhkiG9w0BAQEFAANJADBGAkEA8pmEfmP0Ibir91x6pbts
4JmmsVZd3xvD5p347EFvBCbhBW1nv1GsbCBEFlSiT1q2qvxGb5IlbrfdhdgyqdTX
UQIBATANBgkqhkiG9w0BAQUFAANBAAAB////////////////////////////////
//8AMCEwCQYFKw4DAhoFAAQUePiv+QrJxyjtEJNnH5pB9OTWIqA=
-----END CERTIFICATE-----
    CERT
  end

end

class BasicAuthServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req,res)
    htpd = WEBrick::HTTPAuth::Htpasswd.new('dot.htpasswd')
    htpd.set_passwd('Blah', 'user', 'pass')
    authenticator = WEBrick::HTTPAuth::BasicAuth.new({
      :UserDB => htpd,
      :Realm  => 'Blah',
      :Logger => Logger.new(nil)
    }
                                                    )
                                                    begin
                                                      authenticator.authenticate(req,res)
                                                      res.body = 'You are authenticated'
                                                    rescue WEBrick::HTTPStatus::Unauthorized
                                                      res.status = 401
                                                    end
                                                    FileUtils.rm('dot.htpasswd')
  end
  alias :do_POST :do_GET
end

class ContentTypeServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    ct = req.query['ct'] || "text/html; charset=utf-8"
    res['Content-Type'] = ct
    res.body = "Hello World"
  end
end

class DigestAuthServlet < WEBrick::HTTPServlet::AbstractServlet
  htpd = WEBrick::HTTPAuth::Htdigest.new('digest.htpasswd')
  htpd.set_passwd('Blah', 'user', 'pass')
  @@authenticator = WEBrick::HTTPAuth::DigestAuth.new({
    :UserDB => htpd,
    :Realm  => 'Blah',
    :Algorithm => 'MD5',
    :Logger => Logger.new(nil)
  }
                                                     )
                                                     def do_GET(req,res)
                                                       def req.request_time; Time.now; end
                                                       def req.request_uri; '/digest_auth'; end
                                                       def req.request_method; "GET"; end

                                                       begin
                                                         @@authenticator.authenticate(req,res)
                                                         res.body = 'You are authenticated'
                                                       rescue WEBrick::HTTPStatus::Unauthorized
                                                         res.status = 401
                                                       end
                                                       FileUtils.rm('digest.htpasswd') if File.exists?('digest.htpasswd')
                                                     end
                                                     alias :do_POST :do_GET
end

class FileUploadServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_POST(req, res)
    res.body = req.body
  end
end

class FormServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.body = "<HTML><body>"
    req.query.each_key { |k|
      req.query[k].each_data { |data|
        res.body << "<a href=\"#\">#{WEBrick::HTTPUtils.unescape(k)}:#{WEBrick::HTTPUtils.unescape(data)}</a><br />"
      }
    }
    res.body << "<div id=\"query\">#{res.query}</div></body></HTML>"
    res['Content-Type'] = "text/html"
  end

  def do_POST(req, res)
    res.body = "<HTML><body>"

    req.query.each_key { |k|
      req.query[k].each_data { |data|
        res.body << "<a href=\"#\">#{k}:#{data}</a><br />"
      }
    }

    res.body << "<div id=\"query\">#{req.body}</div></body></HTML>"
    res['Content-Type'] = "text/html"
  end
end

class GzipServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    if req['Accept-Encoding'] =~ /gzip/
      if name = req.query['file'] then
        open("#{Mechanize::TestCase::TEST_DIR}/htdocs/#{name}", 'r') do |io|
          string = ""
          zipped = StringIO.new string, 'w'
          Zlib::GzipWriter.wrap zipped do |gz|
            gz.write io.read
          end
          res.body = string
        end
      else
        res.body = ''
      end
    res['Content-Encoding'] = req['X-ResponseContentEncoding'] || 'gzip'
    res['Content-Type'] = "text/html"
    else
      res.code = 400
      res.body = 'no gzip'
    end
  end
end

class HeaderServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "text/html"

    req.query.each do |x,y|
      res[x] = y
    end

    body = ''
    req.each_header do |k,v|
      body << "#{k}|#{v}\n"
    end
    res.body = body
  end
end

class HttpRefreshServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    refresh_time = req.query['refresh_time'] || 0
    refresh_url = req.query['refresh_url'] || '/index.html'
    res['Refresh'] = " #{refresh_time};url=#{refresh_url}\r\n";
  end
end

class InfiniteRedirectServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    res.status = req.query['code'] ? req.query['code'].to_i : '302'
    number = req.query['q'] ? req.query['q'].to_i : 0
    res['Location'] = "/infinite_redirect?q=#{number + 1}"
  end
  alias :do_POST :do_GET
end

class InfiniteRefreshServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    res.status = req.query['code'] ? req.query['code'].to_i : '302'
    number = req.query['q'] ? req.query['q'].to_i : 0
    res['Refresh'] = " 0;url=http://localhost/infinite_refresh?q=#{number + 1}\r\n";
  end
end

class ManyCookiesAsStringServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    cookies = []
    name_cookie = WEBrick::Cookie.new("name", "Aaron")
    name_cookie.path = "/"
    name_cookie.expires = Time.now + 86400
    name_cookie.domain = 'localhost'
    cookies << name_cookie
    cookies << name_cookie
    cookies << name_cookie
    cookies << "#{name_cookie}; HttpOnly"

    expired_cookie = WEBrick::Cookie.new("expired", "doh")
    expired_cookie.path = "/"
    expired_cookie.expires = Time.now - 86400
    cookies << expired_cookie

    different_path_cookie = WEBrick::Cookie.new("a_path", "some_path")
    different_path_cookie.path = "/some_path"
    different_path_cookie.expires = Time.now + 86400
    cookies << different_path_cookie

    no_path_cookie = WEBrick::Cookie.new("no_path", "no_path")
    no_path_cookie.expires = Time.now + 86400
    cookies << no_path_cookie

    no_exp_path_cookie = WEBrick::Cookie.new("no_expires", "nope")
    no_exp_path_cookie.path = "/"
    cookies << no_exp_path_cookie

    res['Set-Cookie'] = cookies.join(', ')

    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class ManyCookiesServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    name_cookie = WEBrick::Cookie.new("name", "Aaron")
    name_cookie.path = "/"
    name_cookie.expires = Time.now + 86400
    res.cookies << name_cookie
    res.cookies << name_cookie
    res.cookies << name_cookie
    res.cookies << name_cookie

    expired_cookie = WEBrick::Cookie.new("expired", "doh")
    expired_cookie.path = "/"
    expired_cookie.expires = Time.now - 86400
    res.cookies << expired_cookie

    different_path_cookie = WEBrick::Cookie.new("a_path", "some_path")
    different_path_cookie.path = "/some_path"
    different_path_cookie.expires = Time.now + 86400
    res.cookies << different_path_cookie

    no_path_cookie = WEBrick::Cookie.new("no_path", "no_path")
    no_path_cookie.expires = Time.now + 86400
    res.cookies << no_path_cookie

    no_exp_path_cookie = WEBrick::Cookie.new("no_expires", "nope")
    no_exp_path_cookie.path = "/"
    res.cookies << no_exp_path_cookie

    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class ModifiedSinceServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    s_time = 'Fri, 04 May 2001 00:00:38 GMT'

    my_time = Time.parse(s_time)

    if req['If-Modified-Since']
      your_time = Time.parse(req['If-Modified-Since'])
      if my_time > your_time
        res.body = 'This page was updated since you requested'
      else
        res.status = 304
      end
    else
      res.body = 'You did not send an If-Modified-Since header'
    end

    res['Last-Modified'] = s_time
  end
end

class NTLMServlet < WEBrick::HTTPServlet::AbstractServlet

  def do_GET(req, res)
    if req['Authorization'] =~ /^NTLM (.*)/ then
      authorization = $1.unpack('m*').first

      if authorization =~ /^NTLMSSP\000\001/ then
        type_2 = 'TlRMTVNTUAACAAAADAAMADAAAAABAoEAASNFZ4mr' \
          'ze8AAAAAAAAAAGIAYgA8AAAARABPAE0AQQBJAE4A' \
          'AgAMAEQATwBNAEEASQBOAAEADABTAEUAUgBWAEUA' \
          'UgAEABQAZABvAG0AYQBpAG4ALgBjAG8AbQADACIA' \
          'cwBlAHIAdgBlAHIALgBkAG8AbQBhAGkAbgAuAGMA' \
          'bwBtAAAAAAA='

        res['WWW-Authenticate'] = "NTLM #{type_2}"
        res.status = 401
      elsif authorization =~ /^NTLMSSP\000\003/ then
        res.body = 'ok'
      else
        res['WWW-Authenticate'] = 'NTLM'
        res.status = 401
      end
    else
      res['WWW-Authenticate'] = 'NTLM'
      res.status = 401
    end
  end

end

class OneCookieNoSpacesServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    cookie = WEBrick::Cookie.new("foo", "bar")
    cookie.path = "/"
    cookie.expires = Time.now + 86400
    res.cookies << cookie.to_s.gsub(/; /, ';')
    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class OneCookieServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    cookie = WEBrick::Cookie.new("foo", "bar")
    cookie.path = "/"
    cookie.expires = Time.now + 86400
    res.cookies << cookie
    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class QuotedValueCookieServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    cookie = WEBrick::Cookie.new("quoted", "\"value\"")
    cookie.path = "/"
    cookie.expires = Time.now + 86400
    res.cookies << cookie
    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class RedirectServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    res.status = req.query['code'] ? req.query['code'].to_i : '302'
    res['Location'] = "/verb"
  end

  alias :do_POST :do_GET
  alias :do_HEAD :do_GET
  alias :do_PUT :do_GET
  alias :do_DELETE :do_GET
end

class RefererServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "text/html"
    res.body = req['Referer'] || ''
  end

  def do_POST(req, res)
    res['Content-Type'] = "text/html"
    res.body = req['Referer'] || ''
  end
end

class RefreshWithoutUrl < WEBrick::HTTPServlet::AbstractServlet
  @@count = 0
  def do_GET(req, res)
    res['Content-Type'] = "text/html"
    @@count += 1
    if @@count > 1
      res['Refresh'] = "0; url=http://localhost/index.html";
    else
      res['Refresh'] = "0";
    end
  end
end

class RefreshWithEmptyUrl < WEBrick::HTTPServlet::AbstractServlet
  @@count = 0
  def do_GET(req, res)
    res['Content-Type'] = "text/html"
    @@count += 1
    if @@count > 1
      res['Refresh'] = "0; url=http://localhost/index.html";
    else
      res['Refresh'] = "0; url=";
    end
  end
end

class ResponseCodeServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    if req.query['code']
      code = req.query['code'].to_i
      case code
      when 300, 301, 302, 303, 304, 305, 307
        res['Location'] = "/index.html"
      end
      res.status = code
    else
    end
  end
end

class SendCookiesServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "text/html"
    res.body = "<html><body>"
    req.cookies.each { |c|
      res.body << "<a href=\"#\">#{c.name}:#{c.value}</a>"
    }
    res.body << "</body></html>"
  end
end

class VerbServlet < WEBrick::HTTPServlet::AbstractServlet
  %w(HEAD GET POST PUT DELETE).each do |verb|
    eval(<<-eomethod)
      def do_#{verb}(req, res)
        res.header['X-Request-Method'] = #{verb.dump}
      end
        eomethod
  end
end

class Net::HTTP
  alias :old_do_start :do_start

  def do_start
    @started = true
  end

  SERVLETS = {
    '/gzip'                   => GzipServlet,
    '/form_post'              => FormServlet,
    '/basic_auth'             => BasicAuthServlet,
    '/form post'              => FormServlet,
    '/response_code'          => ResponseCodeServlet,
    '/http_refresh'           => HttpRefreshServlet,
    '/content_type_test'      => ContentTypeServlet,
    '/referer'                => RefererServlet,
    '/file_upload'            => FileUploadServlet,
    '/one_cookie'             => OneCookieServlet,
    '/one_cookie_no_space'    => OneCookieNoSpacesServlet,
    '/many_cookies'           => ManyCookiesServlet,
    '/many_cookies_as_string' => ManyCookiesAsStringServlet,
    '/ntlm'                   => NTLMServlet,
    '/send_cookies'           => SendCookiesServlet,
    '/quoted_value_cookie'    => QuotedValueCookieServlet,
    '/if_modified_since'      => ModifiedSinceServlet,
    '/http_headers'           => HeaderServlet,
    '/infinite_redirect'      => InfiniteRedirectServlet,
    '/infinite_refresh'       => InfiniteRefreshServlet,
    '/redirect'               => RedirectServlet,
    '/refresh_without_url'    => RefreshWithoutUrl,
    '/refresh_with_empty_url' => RefreshWithEmptyUrl,
    '/digest_auth'            => DigestAuthServlet,
    '/verb'                   => VerbServlet,
  }

  PAGE_CACHE = {}

  alias :old_request :request

  def request(req, *data, &block)
    url = URI.parse(req.path)
    path = WEBrick::HTTPUtils.unescape(url.path)

    path = '/index.html' if path == '/'

    res = ::Response.new
    res.query_params = url.query

    req.query = if 'POST' != req.method && url.query then
                  WEBrick::HTTPUtils.parse_query url.query
                elsif req['content-type'] =~ /www-form-urlencoded/ then
                  WEBrick::HTTPUtils.parse_query req.body
                elsif req['content-type'] =~ /boundary=(.+)/ then
                  boundary = WEBrick::HTTPUtils.dequote $1
                  WEBrick::HTTPUtils.parse_form_data req.body, boundary
                else
                  {}
                end

    req.cookies = WEBrick::Cookie.parse(req['Cookie'])

    Mechanize::TestCase::REQUESTS << req

    if servlet_klass = SERVLETS[path]
      servlet = servlet_klass.new({})
      servlet.send "do_#{req.method}", req, res
    else
      filename = "htdocs#{path.gsub(/[^\/\\.\w\s]/, '_')}"
      unless PAGE_CACHE[filename]
        open("#{Mechanize::TestCase::TEST_DIR}/#{filename}", 'rb') { |io|
          PAGE_CACHE[filename] = io.read
        }
      end

      res.body = PAGE_CACHE[filename]
      case filename
      when /\.txt$/
        res['Content-Type'] = 'text/plain'
      when /\.jpg$/
        res['Content-Type'] = 'image/jpeg'
      end
    end

    res['Content-Type'] ||= 'text/html'
    res.code ||= "200"

    response_klass = Net::HTTPResponse::CODE_TO_OBJ[res.code.to_s]
    response = response_klass.new res.http_version, res.code, res.message

    res.header.each do |k,v|
      v = v.first if v.length == 1
      response[k] = v
    end

    res.cookies.each do |cookie|
      response.add_field 'Set-Cookie', cookie.to_s
    end

    response['Content-Type'] ||= 'text/html'
    response['Content-Length'] = res['Content-Length'] || res.body.length.to_s

    io = StringIO.new(res.body)
    response.instance_variable_set :@socket, io
    def io.read clen, dest, _
      dest << string[0, clen]
    end

    body_exist = req.response_body_permitted? &&
      response_klass.body_permitted?

    response.instance_variable_set :@body_exist, body_exist

    yield response if block_given?

    response
  end
end

class Net::HTTPRequest
  attr_accessor :query, :body, :cookies, :user
end

class Response
  include Net::HTTPHeader

  attr_reader :code
  attr_accessor :body, :query, :cookies
  attr_accessor :query_params, :http_version
  attr_accessor :header

  def code=(c)
    @code = c.to_s
  end

  alias :status :code
  alias :status= :code=

    def initialize
      @header = {}
      @body = ''
      @code = nil
      @query = nil
      @cookies = []
      @http_version = '1.1'
    end

  def read_body
    yield body
  end

  def message
    ''
  end
end

