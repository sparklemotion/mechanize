require 'webrick'
require 'servlets'

s = WEBrick::HTTPServer.new(
  :Port           => 2000,
  :DocumentRoot   => Dir::pwd + "/htdocs"
)
s.mount("/one_cookie", OneCookieTest)
s.mount("/many_cookies", ManyCookiesTest)
s.mount("/many_cookies_as_string", ManyCookiesAsStringTest)
s.mount("/send_cookies", SendCookiesTest)
s.mount("/form_post", FormTest)
s.mount("/form post", FormTest)

trap("INT") { s.stop }

s.start

