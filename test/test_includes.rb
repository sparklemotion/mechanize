require 'net/http'
require 'test_servlets'
require 'webrick/httputils'

BASE_DIR = File.dirname(__FILE__)

class Net::HTTP
  #def self.new(*args)
  #  obj = allocate
  #  return obj
  #end

  alias :old_do_start :do_start

  def do_start
    @started = true
  end

  SERVLETS = {
    '/gzip'                   => GzipServlet,
    '/form_post'              => FormTest,
    '/basic_auth'             => BasicAuthServlet,
    '/form post'              => FormTest,
    '/response_code'          => ResponseCodeTest,
    '/bad_content_type'       => BadContentTypeTest,
    '/content_type_test'      => ContentTypeTest,
    '/referer'                => RefererServlet,
    '/file_upload'            => FileUploadTest,
    '/one_cookie'             => OneCookieTest,
    '/one_cookie_no_space'    => OneCookieNoSpacesTest,
    '/many_cookies'           => ManyCookiesTest,
    '/many_cookies_as_string' => ManyCookiesAsStringTest,
    '/send_cookies'           => SendCookiesTest,
    '/if_modified_since'      => ModifiedSinceServlet,
    '/http_headers'           => HeaderServlet,
  }

  PAGE_CACHE = {}

  alias :old_request :request

  def request(request, *data, &block)
    url = URI.parse(request.path)
    path = URI.unescape(url.path)

    path = '/index.html' if path == '/'

    res = Response.new
    request.query = WEBrick::HTTPUtils.parse_query(url.query)
    request.cookies = WEBrick::Cookie.parse(request['Cookie'])
    if SERVLETS[path]
      if request.method == "POST"
        if request['Content-Type'] =~ /^multipart\/form-data/
          request.body = data.first
        else
          request.query = WEBrick::HTTPUtils.parse_query(data.first)
        end
      end
      SERVLETS[path].new({}).send("do_#{request.method}", request, res)
    else
      filename = "htdocs#{path.gsub(/[^\/\\.\w_\s]/, '_')}"
      unless PAGE_CACHE[filename]
        File.open("#{BASE_DIR}/#{filename}", 'rb') { |file|
          PAGE_CACHE[filename] = file.read
        }
      end
      res.body = PAGE_CACHE[filename]
    end

    res['Content-Type'] ||= 'text/html'
    res['Content-Length'] ||= res.body.length.to_s
    res.code ||= "200"

    res.cookies.each do |cookie|
      res.add_field('Set-Cookie', cookie.to_s)
    end
    yield res if block_given?
    res
  end
end

class Net::HTTPRequest
  attr_accessor :query, :body, :cookies, :user
end

class Response
  include Net::HTTPHeader

  attr_reader :code
  attr_accessor :body, :query, :cookies
  
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
  end

  def read_body
    yield body
  end
end


module TestMethods
  PORT      = 2000
  PROXYPORT = 2001
  SSLPORT   = 2002

  def html_response
    { 'content-type' => 'text/html' }
  end
end
