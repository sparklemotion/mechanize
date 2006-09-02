$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'mechanize/cookie'
require 'uri'
require 'test_includes'
require 'fileutils'

class CookieJarTest < Test::Unit::TestCase
  def cookie_from_hash(hash)
    c = WWW::Mechanize::Cookie.new(hash[:name], hash[:value])
    hash.each { |k,v|
      next if k == :name || k == :value
      c.send("#{k}=", v)
    }
    c
  end
  def test_add_future_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    jar.add(cookie_from_hash(values))
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
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    jar.add(cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Make sure we can't get the cookie from different domains
    assert_equal(0, jar.cookies(URI.parse('http://google.com/')).length)
  end

  def test_clear_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    jar.add(cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    jar.clear!

    assert_equal(0, jar.cookies(url).length)
  end

  def test_save_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    jar.add(cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    jar.save_as("cookies.yml")
    jar.clear!
    assert_equal(0, jar.cookies(url).length)

    jar.load("cookies.yml")
    assert_equal(2, jar.cookies(url).length)
    FileUtils.rm("cookies.yml")
  end

  def test_expire_cookies
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    jar.add(cookie_from_hash(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(cookie_from_hash(values.merge( :name => 'Baz',
                                          :expires => Time.now - (10 * 86400))))
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

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    jar.add(cookie_from_hash(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(cookie_from_hash(values.merge( :name => 'Baz',
                                          :expires => Time.now - (10 * 86400))))
    assert_equal(0, jar.cookies(url).length)

    # When given a URI with a blank path, CookieJar#cookies should return
    # cookies with the path '/':
    url = URI.parse('http://rubyforge.org')
    assert_equal '', url.path    
    assert_equal(0, jar.cookies(url).length)    
    # Now add a cookie with the path set to '/':
    jar.add(cookie_from_hash(values.merge( :name => 'has_root_path', 
                                          :path => '/')))    
    assert_equal(1, jar.cookies(url).length)
  end

  def test_paths
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/login',
                :expires  => nil,
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/login')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we don't get the cookie in a different path
    assert_equal(0, jar.cookies(URI.parse('http://rubyforge.org/hello')).length)
    assert_equal(0, jar.cookies(URI.parse('http://rubyforge.org/')).length)

    # Expire the first cookie
    jar.add(cookie_from_hash(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(cookie_from_hash(values.merge( :name => 'Baz',
                                          :expires => Time.now - (10 * 86400))))
    assert_equal(0, jar.cookies(url).length)
  end
end
