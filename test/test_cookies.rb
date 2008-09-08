require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class CookiesMechTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_meta_tag_cookies
    cookies = @agent.cookies.length
    page = @agent.get("http://localhost/meta_cookie.html")
    assert_equal(cookies + 1, @agent.cookies.length)
  end

  def test_send_cookies
    page = @agent.get("http://localhost/many_cookies")
    page = @agent.get("http://localhost/send_cookies")
    assert_equal(3, page.links.length)
    assert_not_nil(page.links.find { |l| l.text == "name:Aaron" })
    assert_not_nil(page.links.find { |l| l.text == "no_expires:nope" })
  end

  def test_no_space_cookies
    page = @agent.get("http://localhost/one_cookie_no_space")
    assert_equal(1, @agent.cookies.length)
    foo_cookie = @agent.cookies.find { |k| k.name == 'foo' }
    assert_not_nil(foo_cookie, 'Foo cookie was nil')
    assert_equal('bar', foo_cookie.value)
    assert_equal('/', foo_cookie.path)
    assert_equal(true, Time.now < foo_cookie.expires)
  end

  def test_many_cookies_as_string
    page = @agent.get("http://localhost/many_cookies_as_string")
    assert_equal(4, @agent.cookies.length)

    name_cookie = @agent.cookies.find { |k| k.name == "name" }
    assert_not_nil(name_cookie, "Name cookie was nil")
    assert_equal("Aaron", name_cookie.value)
    assert_equal("/", name_cookie.path)
    assert_equal(true, Time.now < name_cookie.expires)

    expired_cookie = @agent.cookies.find { |k| k.name == "expired" }
    assert_nil(expired_cookie, "Expired cookie was not nil")

    no_exp_cookie = @agent.cookies.find { |k| k.name == "no_expires" }
    assert_not_nil(no_exp_cookie, "No expires cookie is nil")
    assert_equal("nope", no_exp_cookie.value)
    assert_equal("/", no_exp_cookie.path)
    assert_nil(no_exp_cookie.expires)

    path_cookie = @agent.cookies.find { |k| k.name == "a_path" }
    assert_not_nil(path_cookie, "Path cookie is nil")
    assert_equal("some_path", path_cookie.value)
    assert_equal(true, Time.now < path_cookie.expires)

    no_path_cookie = @agent.cookies.find { |k| k.name == "no_path" }
    assert_not_nil(no_path_cookie, "No path cookie is nil")
    assert_equal("no_path", no_path_cookie.value)
    assert_equal("/", no_path_cookie.path)
    assert_equal(true, Time.now < no_path_cookie.expires)
  end

  def test_many_cookies
    page = @agent.get("http://localhost/many_cookies")
    assert_equal(4, @agent.cookies.length)

    name_cookie = @agent.cookies.find { |k| k.name == "name" }
    assert_not_nil(name_cookie, "Name cookie was nil")
    assert_equal("Aaron", name_cookie.value)
    assert_equal("/", name_cookie.path)
    assert_equal(true, Time.now < name_cookie.expires)

    expired_cookie = @agent.cookies.find { |k| k.name == "expired" }
    assert_nil(expired_cookie, "Expired cookie was not nil")

    no_exp_cookie = @agent.cookies.find { |k| k.name == "no_expires" }
    assert_not_nil(no_exp_cookie, "No expires cookie is nil")
    assert_equal("nope", no_exp_cookie.value)
    assert_equal("/", no_exp_cookie.path)
    assert_nil(no_exp_cookie.expires)

    path_cookie = @agent.cookies.find { |k| k.name == "a_path" }
    assert_not_nil(path_cookie, "Path cookie is nil")
    assert_equal("some_path", path_cookie.value)
    assert_equal(true, Time.now < path_cookie.expires)

    no_path_cookie = @agent.cookies.find { |k| k.name == "no_path" }
    assert_not_nil(no_path_cookie, "No path cookie is nil")
    assert_equal("no_path", no_path_cookie.value)
    assert_equal("/", no_path_cookie.path)
    assert_equal(true, Time.now < no_path_cookie.expires)
  end

  def test_get_cookie
    assert_equal(true,
      @agent.cookie_jar.empty?(
      URI::parse("http://localhost/one_cookie")))

    assert_equal(0, @agent.cookies.length)

    page = @agent.get("http://localhost/one_cookie")
    assert_equal(1, @agent.cookies.length)

    cookie = @agent.cookies.first
    assert_equal("foo", cookie.name)
    assert_equal("bar", cookie.value)
    assert_equal("/", cookie.path)
    assert_equal("localhost", cookie.domain)

    assert_equal(false,
      @agent.cookie_jar.empty?(
      URI::parse("http://localhost/one_cookie")))
    page = @agent.get("http://localhost/one_cookie")

    assert_equal(1, @agent.cookies.length)

    cookie = @agent.cookies.first
    assert_equal("foo", cookie.name)
    assert_equal("bar", cookie.value)
    assert_equal("/", cookie.path)
    assert_equal("localhost", cookie.domain)
  end
end
