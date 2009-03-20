require 'webrick'
require 'logger'
require 'date'
require 'zlib'
require 'stringio'
require 'base64'

class VerbServlet < WEBrick::HTTPServlet::AbstractServlet
  %w(HEAD GET POST PUT DELETE).each do |verb|
    eval(<<-eomethod)
      def do_#{verb}(req, res)
        res.body = "method: #{verb}"
      end
    eomethod
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
    rescue WEBrick::HTTPStatus::Unauthorized => ex
      res.status = 401
    end
    FileUtils.rm('dot.htpasswd')
  end
  alias :do_POST :do_GET
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
    rescue WEBrick::HTTPStatus::Unauthorized => ex
      res.status = 401
    end
    FileUtils.rm('digest.htpasswd') if File.exists?('digest.htpasswd')
  end
  alias :do_POST :do_GET
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

class GzipServlet < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    if req['Accept-Encoding'] =~ /gzip/
      if req.query['file']
        File.open("#{BASE_DIR}/htdocs/#{req.query['file']}", 'r') do |file|
          string = ""
          zipped = StringIO.new string, 'w'
          gz = Zlib::GzipWriter.new(zipped)
          gz.write file.read
          gz.close
          res.body = string
        end
      else
        res.body = ''
      end
      res['Content-Encoding'] = 'gzip'
      res['Content-Type'] = "text/html"
    else
      raise 'no gzip'
    end
  end
end

class BadContentTypeTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "text/xml"
    res.body = "Hello World"
  end
end

class ContentTypeTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    ct = req.query['ct'] || "text/html; charset=utf-8"
    res['Content-Type'] = ct
    res.body = "Hello World"
  end
end

class FileUploadTest < WEBrick::HTTPServlet::AbstractServlet
  def do_POST(req, res)
    res.body = req.body
  end
end

class InfiniteRefreshTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    res.status = req.query['code'] ? req.query['code'].to_i : '302'
    number = req.query['q'] ? req.query['q'].to_i : 0
    res['Refresh'] = " 0;url=http://localhost/infinite_refresh?q=#{number + 1}\r\n";
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

class InfiniteRedirectTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    res.status = req.query['code'] ? req.query['code'].to_i : '302'
    number = req.query['q'] ? req.query['q'].to_i : 0
    res['Location'] = "/infinite_redirect?q=#{number + 1}"
  end
  alias :do_POST :do_GET
end

class RedirectTest < WEBrick::HTTPServlet::AbstractServlet
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

class ResponseCodeTest < WEBrick::HTTPServlet::AbstractServlet
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

class HttpRefreshTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = req.query['ct'] || "text/html"
    refresh_time = req.query['refresh_time'] || 0
    refresh_url = req.query['refresh_url'] || '/index.html'
    res['Refresh'] = " #{refresh_time};url=#{refresh_url}\r\n";
  end
end

class FormTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.body = "<HTML><body>"
    req.query.each_key { |k|
      req.query[k].each_data { |data|
        res.body << "<a href=\"#\">#{URI.unescape(k)}:#{URI.unescape(data)}</a><br />"
      }
    }
    res.body << "</body></HTML>"
    res['Content-Type'] = "text/html"
  end

  def do_POST(req, res)
    res.body = "<HTML><body>"
    req.query.each_key { |k|
      req.query[k].each_data { |data|
        res.body << "<a href=\"#\">#{k}:#{data}</a><br />"
      }
    }
    res.body << "</body></HTML>"
    res['Content-Type'] = "text/html"
  end
end

class OneCookieTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    cookie = WEBrick::Cookie.new("foo", "bar")
    cookie.path = "/"
    cookie.expires = Time.now + 86400
    res.cookies << cookie
    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class OneCookieNoSpacesTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    cookie = WEBrick::Cookie.new("foo", "bar")
    cookie.path = "/"
    cookie.expires = Time.now + 86400
    res.cookies << cookie.to_s.gsub(/; /, ';')
    res['Content-Type'] = "text/html"
    res.body = "<html><body>hello</body></html>"
  end
end

class ManyCookiesTest < WEBrick::HTTPServlet::AbstractServlet
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

class ManyCookiesAsStringTest < WEBrick::HTTPServlet::AbstractServlet
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

class SendCookiesTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res['Content-Type'] = "text/html"
    res.body = "<html><body>"
    req.cookies.each { |c| 
      res.body << "<a href=\"#\">#{c.name}:#{c.value}</a>"
    }
    res.body << "</body></html>"
  end
end
