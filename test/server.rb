require 'webrick'
require 'servlets'
require 'logger'

s = WEBrick::HTTPServer.new(
  :Port           => 2000,
  :DocumentRoot   => Dir::pwd + "/htdocs",
  :Logger         => Logger.new(nil),
  :AccessLog      => Logger.new(nil)
)
s.mount("/one_cookie", OneCookieTest)
s.mount("/many_cookies", ManyCookiesTest)
s.mount("/many_cookies_as_string", ManyCookiesAsStringTest)
s.mount("/send_cookies", SendCookiesTest)
s.mount("/form_post", FormTest)
s.mount("/form post", FormTest)
s.mount("/response_code", ResponseCodeTest)
s.mount("/file_upload", FileUploadTest)

trap("INT") { s.stop }

s.start

