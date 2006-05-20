$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'mechanize/cookie'
require 'uri'
require 'test_includes'

class CookieJarTest < Test::Unit::TestCase
  def test_add_future_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => DateTime.now + 10,
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = WWW::Cookie.new(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    jar.add(WWW::Cookie.new(values))
    assert_equal(1, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(1, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Make sure we can't get the cookie from different domains
    assert_equal(0, jar.cookies(URI.parse('http://google.com/')).length)
  end

  def test_add_multiple_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => DateTime.now + 10,
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = WWW::Cookie.new(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Make sure we can't get the cookie from different domains
    assert_equal(0, jar.cookies(URI.parse('http://google.com/')).length)
  end

  def test_expire_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => DateTime.now + 10,
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = WWW::Cookie.new(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    jar.add(WWW::Cookie.new(values.merge( :expires => DateTime.now - 10)))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz',
                                          :expires => DateTime.now - 10)))
    assert_equal(0, jar.cookies(url).length)
  end

  def test_session_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => nil,
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = WWW::Cookie.new(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    jar.add(WWW::Cookie.new(values.merge( :expires => DateTime.now - 10)))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz',
                                          :expires => DateTime.now - 10)))
    assert_equal(0, jar.cookies(url).length)
  end

  def test_paths
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/login',
                :expires  => nil,
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/login')

    jar = WWW::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = WWW::Cookie.new(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we don't get the cookie in a different path
    assert_equal(0, jar.cookies(URI.parse('http://rubyforge.org/hello')).length)
    assert_equal(0, jar.cookies(URI.parse('http://rubyforge.org/')).length)

    # Expire the first cookie
    jar.add(WWW::Cookie.new(values.merge( :expires => DateTime.now - 10)))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(WWW::Cookie.new(values.merge( :name => 'Baz',
                                          :expires => DateTime.now - 10)))
    assert_equal(0, jar.cookies(url).length)
  end
end
