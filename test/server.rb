require 'webrick'
require 'base64'
require 'servlets'
require 'logger'

base_dir = FileTest.exists?(Dir::pwd + '/test') ? Dir::pwd + '/test' : Dir::pwd

s = WEBrick::HTTPServer.new(
  :Port           => 2000,
  :DocumentRoot   => base_dir + "/htdocs",
  :Logger         => Logger.new(nil),
  :AccessLog      => Logger.new(nil)
)
s.mount("/one_cookie", OneCookieTest)
s.mount("/one_cookie_no_space", OneCookieNoSpacesTest)
s.mount("/many_cookies", ManyCookiesTest)
s.mount("/many_cookies_as_string", ManyCookiesAsStringTest)
s.mount("/send_cookies", SendCookiesTest)
s.mount("/form_post", FormTest)
s.mount("/form post", FormTest)
s.mount("/response_code", ResponseCodeTest)
s.mount("/file_upload", FileUploadTest)
s.mount("/bad_content_type", BadContentTypeTest)
s.mount("/content_type_test", ContentTypeTest)
s.mount("/gzip", GzipServlet)

htpasswd = WEBrick::HTTPAuth::Htpasswd.new(base_dir + '/data/htpasswd')
auth = WEBrick::HTTPAuth::BasicAuth.new(
  :UserDB => htpasswd,
  :Realm  => 'mechanize',
  :Logger         => Logger.new(nil),
  :AccessLog      => Logger.new(nil)
)
s.mount_proc('/htpasswd_auth') { |req, res|
  auth.authenticate(req, res)
  res.body = "You are authenticated"
}

trap("INT") { s.stop }

s.start

