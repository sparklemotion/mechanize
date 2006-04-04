$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'net/http'
require 'uri'
require 'test_includes'

class FormsMechTest < Test::Unit::TestCase
  include TestMethods

  def test_send_cookies
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/many_cookies")
    page = agent.get("http://localhost:#{@port}/send_cookies")
    assert_equal(2, page.links.length)
    assert_not_nil(page.links.find { |l| l.text == "name:Aaron" })
    assert_not_nil(page.links.find { |l| l.text == "no_expires:nope" })
  end

  def test_many_cookies_as_string
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/many_cookies_as_string")
    assert_equal(5, agent.cookies.length)

    name_cookie = agent.cookies.find { |k| k.name == "name" }
    assert_not_nil(name_cookie, "Name cookie was nil")
    assert_equal("Aaron", name_cookie.value)
    assert_equal("/", name_cookie.path)
    assert_equal(true, DateTime.now < name_cookie.expires)

    expired_cookie = agent.cookies.find { |k| k.name == "expired" }
    assert_not_nil(expired_cookie, "Expired cookie was nil")
    assert_equal("doh", expired_cookie.value)
    assert_equal("/", expired_cookie.path)
    assert_equal(true, DateTime.now > expired_cookie.expires)

    no_exp_cookie = agent.cookies.find { |k| k.name == "no_expires" }
    assert_not_nil(no_exp_cookie, "No expires cookie is nil")
    assert_equal("nope", no_exp_cookie.value)
    assert_equal("/", no_exp_cookie.path)
    assert_nil(no_exp_cookie.expires)

    path_cookie = agent.cookies.find { |k| k.name == "a_path" }
    assert_not_nil(path_cookie, "Path cookie is nil")
    assert_equal("some_path", path_cookie.value)
    assert_equal(true, DateTime.now < path_cookie.expires)

    no_path_cookie = agent.cookies.find { |k| k.name == "no_path" }
    assert_not_nil(no_path_cookie, "No path cookie is nil")
    assert_equal("no_path", no_path_cookie.value)
    assert_equal("/many_cookies_as_string", no_path_cookie.path)
    assert_equal(true, DateTime.now < no_path_cookie.expires)
  end

  def test_many_cookies
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/many_cookies")
    assert_equal(5, agent.cookies.length)

    name_cookie = agent.cookies.find { |k| k.name == "name" }
    assert_not_nil(name_cookie, "Name cookie was nil")
    assert_equal("Aaron", name_cookie.value)
    assert_equal("/", name_cookie.path)
    assert_equal(true, DateTime.now < name_cookie.expires)

    expired_cookie = agent.cookies.find { |k| k.name == "expired" }
    assert_not_nil(expired_cookie, "Expired cookie was nil")
    assert_equal("doh", expired_cookie.value)
    assert_equal("/", expired_cookie.path)
    assert_equal(true, DateTime.now > expired_cookie.expires)

    no_exp_cookie = agent.cookies.find { |k| k.name == "no_expires" }
    assert_not_nil(no_exp_cookie, "No expires cookie is nil")
    assert_equal("nope", no_exp_cookie.value)
    assert_equal("/", no_exp_cookie.path)
    assert_nil(no_exp_cookie.expires)

    path_cookie = agent.cookies.find { |k| k.name == "a_path" }
    assert_not_nil(path_cookie, "Path cookie is nil")
    assert_equal("some_path", path_cookie.value)
    assert_equal(true, DateTime.now < path_cookie.expires)

    no_path_cookie = agent.cookies.find { |k| k.name == "no_path" }
    assert_not_nil(no_path_cookie, "No path cookie is nil")
    assert_equal("no_path", no_path_cookie.value)
    assert_equal("/many_cookies", no_path_cookie.path)
    assert_equal(true, DateTime.now < no_path_cookie.expires)
  end

  def test_get_cookie
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    assert_equal(true,
      agent.cookie_jar.empty?(
      URI::parse("http://localhost:#{@port}/one_cookie")))

    assert_equal(0, agent.cookies.length)

    page = agent.get("http://localhost:#{@port}/one_cookie")
    assert_equal(1, agent.cookies.length)

    cookie = agent.cookies.first
    assert_equal("foo", cookie.name)
    assert_equal("bar", cookie.value)
    assert_equal("/", cookie.path)
    assert_equal("localhost", cookie.domain)

    assert_equal(false,
      agent.cookie_jar.empty?(
      URI::parse("http://localhost:#{@port}/one_cookie")))
    page = agent.get("http://localhost:#{@port}/one_cookie")

    assert_equal(1, agent.cookies.length)

    cookie = agent.cookies.first
    assert_equal("foo", cookie.name)
    assert_equal("bar", cookie.value)
    assert_equal("/", cookie.path)
    assert_equal("localhost", cookie.domain)
  end
end
