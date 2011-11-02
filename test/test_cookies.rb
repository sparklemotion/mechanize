require 'mechanize/test_case'

class CookiesMechTest < Mechanize::TestCase

  def test_quoted_value_cookie
    @mech.get("http://localhost/quoted_value_cookie")
    quoted_cookie = @mech.cookies.find { |k| k.name == 'quoted' }
    assert_equal("\"value\"", quoted_cookie.value)
  end

  def test_meta_tag_cookies
    cookies = @mech.cookies.length
    @mech.get("http://localhost/meta_cookie.html")
    assert_equal(cookies + 1, @mech.cookies.length)
  end

  def test_send_cookies
    page = @mech.get("http://localhost/many_cookies")
    page = @mech.get("http://localhost/send_cookies")
    assert_equal(3, page.links.length)
    assert(page.links.find { |l| l.text == "name:Aaron" })
    assert(page.links.find { |l| l.text == "no_expires:nope" })
  end

  def test_no_space_cookies
    @mech.get("http://localhost/one_cookie_no_space")
    assert_equal(1, @mech.cookies.length)
    foo_cookie = @mech.cookies.find { |k| k.name == 'foo' }
    assert(foo_cookie, 'Foo cookie was nil')
    assert_equal('bar', foo_cookie.value)
    assert_equal('/', foo_cookie.path)
    assert_equal(true, Time.now < foo_cookie.expires)
  end

  def test_many_cookies_as_string
    @mech.get("http://localhost/many_cookies_as_string")
    assert_equal(4, @mech.cookies.length)

    name_cookie = @mech.cookies.find { |k| k.name == "name" }

    assert_equal("Aaron", name_cookie.value)
    assert_equal("/", name_cookie.path)
    assert_equal(true, Time.now < name_cookie.expires)

    expired_cookie = @mech.cookies.find { |k| k.name == "expired" }
    assert_nil(expired_cookie, "Expired cookie was not nil")

    no_exp_cookie = @mech.cookies.find { |k| k.name == "no_expires" }

    assert_equal("nope", no_exp_cookie.value)
    assert_equal("/", no_exp_cookie.path)
    assert_nil(no_exp_cookie.expires)

    path_cookie = @mech.cookies.find { |k| k.name == "a_path" }

    assert_equal("some_path", path_cookie.value)
    assert_equal(true, Time.now < path_cookie.expires)

    no_path_cookie = @mech.cookies.find { |k| k.name == "no_path" }

    assert_equal("no_path", no_path_cookie.value)
    assert_equal("/", no_path_cookie.path)
    assert_equal(true, Time.now < no_path_cookie.expires)
  end

  def test_many_cookies
    @mech.get("http://localhost/many_cookies")
    assert_equal(4, @mech.cookies.length)

    name_cookie = @mech.cookies.find { |k| k.name == "name" }
    assert(name_cookie, "Name cookie was nil")
    assert_equal("Aaron", name_cookie.value)
    assert_equal("/", name_cookie.path)
    assert_equal(true, Time.now < name_cookie.expires)

    expired_cookie = @mech.cookies.find { |k| k.name == "expired" }
    assert_nil(expired_cookie, "Expired cookie was not nil")

    no_exp_cookie = @mech.cookies.find { |k| k.name == "no_expires" }
    assert(no_exp_cookie, "No expires cookie is nil")
    assert_equal("nope", no_exp_cookie.value)
    assert_equal("/", no_exp_cookie.path)
    assert_nil(no_exp_cookie.expires)

    path_cookie = @mech.cookies.find { |k| k.name == "a_path" }
    assert(path_cookie, "Path cookie is nil")
    assert_equal("some_path", path_cookie.value)
    assert_equal(true, Time.now < path_cookie.expires)

    no_path_cookie = @mech.cookies.find { |k| k.name == "no_path" }
    assert(no_path_cookie, "No path cookie is nil")
    assert_equal("no_path", no_path_cookie.value)
    assert_equal("/", no_path_cookie.path)
    assert_equal(true, Time.now < no_path_cookie.expires)
  end

  def test_get_cookie
    assert_equal(true,
      @mech.cookie_jar.empty?(
      URI::parse("http://localhost/one_cookie")))

    assert_equal(0, @mech.cookies.length)

    page = @mech.get("http://localhost/one_cookie")
    assert_equal(1, @mech.cookies.length)

    cookie = @mech.cookies.first
    assert_equal("foo", cookie.name)
    assert_equal("bar", cookie.value)
    assert_equal("/", cookie.path)
    assert_equal("localhost", cookie.domain)

    assert_equal(false,
      @mech.cookie_jar.empty?(
      URI::parse("http://localhost/one_cookie")))
    page = @mech.get("http://localhost/one_cookie")

    assert_equal(1, @mech.cookies.length)

    cookie = @mech.cookies.first
    assert_equal("foo", cookie.name)
    assert_equal("bar", cookie.value)
    assert_equal("/", cookie.path)
    assert_equal("localhost", cookie.domain)
  end
end
