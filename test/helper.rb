require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'webrick/httputils'
require 'servlets'

BASE_DIR = File.dirname(__FILE__)

# Move this to a test base class
module MechTestHelper
  def self.fake_page(agent)
    html = <<-END
    <html><body>
    <form><input type="submit" value="submit" /></form>
    </body></html>
    END
    html_response = { 'content-type' => 'text/html' }
    page = Mechanize::Page.new(  nil, html_response, html, 200, agent )
  end
end

class Net::HTTP
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
    '/http_refresh'           => HttpRefreshTest,
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
    '/infinite_redirect'      => InfiniteRedirectTest,
    '/infinite_refresh'       => InfiniteRefreshTest,
    '/redirect'               => RedirectTest,
    '/refresh_without_url'    => RefreshWithoutUrl,
    '/refresh_with_empty_url' => RefreshWithEmptyUrl,
    '/digest_auth'            => DigestAuthServlet,
    '/verb'                   => VerbServlet,
  }

  PAGE_CACHE = {}

  alias :old_request :request

  def request(request, *data, &block)
    url = URI.parse(request.path)
    path = WEBrick::HTTPUtils.unescape(url.path)

    path = '/index.html' if path == '/'

    res = Response.new
    res.query_params = url.query

    request.query = if 'POST' != request.method && url.query then
                      WEBrick::HTTPUtils.parse_query url.query
                    elsif request['content-type'] =~ /www-form-urlencoded/ then
                      WEBrick::HTTPUtils.parse_query request.body
                    elsif request['content-type'] =~ /boundary=(.+)/ then
                      boundary = WEBrick::HTTPUtils.dequote $1
                      WEBrick::HTTPUtils.parse_form_data request.body, boundary
                    else
                      {}
                    end

    request.cookies = WEBrick::Cookie.parse(request['Cookie'])

    if SERVLETS[path]
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
  attr_accessor :query_params

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
