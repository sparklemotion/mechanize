require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class CookieJarTest < Test::Unit::TestCase
  def cookie_from_hash(hash)
    c = WWW::Mechanize::Cookie.new(hash[:name], hash[:value])
    hash.each { |k,v|
      next if k == :name || k == :value
      c.send("#{k}=", v)
    }
    c
  end

  def test_two_cookies_same_domain_and_name_different_paths
    values = {  :name     => 'Foo',
                :value    => 'Bar',
                :path     => '/',
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }

    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    cookie = cookie_from_hash(values)
    jar.add(url, cookie)
    jar.add(url, cookie_from_hash(values.merge(:path => '/onetwo')))

    assert_equal(1, jar.cookies(url).length)
    assert_equal 2, jar.cookies(URI.parse('http://rubyforge.org/onetwo')).length
  end

  def test_domain_case
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
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    jar.add(url, cookie_from_hash( values.merge(  :domain => 'RuByForge.Org',
                                                  :name   => 'aaron'
                                               ) ) )

    assert_equal(2, jar.cookies(url).length)

    url2 = URI.parse('http://RuByFoRgE.oRg/')
    assert_equal(2, jar.cookies(url2).length)
  end

  def test_empty_value
    values = {  :name     => 'Foo',
                :value    => '',
                :path     => '/',
                :expires  => Time.now + (10 * 86400),
                :domain   => 'rubyforge.org'
             }
    url = URI.parse('http://rubyforge.org/')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    # Add one cookie with an expiration date in the future
    cookie = cookie_from_hash(values)
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    jar.add(url, cookie_from_hash( values.merge(  :domain => 'RuByForge.Org',
                                                  :name   => 'aaron'
                                               ) ) )

    assert_equal(2, jar.cookies(url).length)

    url2 = URI.parse('http://RuByFoRgE.oRg/')
    assert_equal(2, jar.cookies(url2).length)
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
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    jar.add(url, cookie_from_hash(values))
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
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
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
    jar.add(url, cookie)
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
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
    jar.add(url, cookie)
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
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
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    jar.add(url, cookie_from_hash(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz',
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
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    jar.add(url, cookie_from_hash(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz',
                                          :expires => Time.now - (10 * 86400))))
    assert_equal(0, jar.cookies(url).length)

    # When given a URI with a blank path, CookieJar#cookies should return
    # cookies with the path '/':
    url = URI.parse('http://rubyforge.org')
    assert_equal '', url.path
    assert_equal(0, jar.cookies(url).length)
    # Now add a cookie with the path set to '/':
    jar.add(url, cookie_from_hash(values.merge( :name => 'has_root_path',
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
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length)

    # Add a second cookie
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    # Make sure we don't get the cookie in a different path
    assert_equal(0, jar.cookies(URI.parse('http://rubyforge.org/hello')).length)
    assert_equal(0, jar.cookies(URI.parse('http://rubyforge.org/')).length)

    # Expire the first cookie
    jar.add(url, cookie_from_hash(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, jar.cookies(url).length)

    # Expire the second cookie
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz',
                                          :expires => Time.now - (10 * 86400))))
    assert_equal(0, jar.cookies(url).length)
  end


  def test_save_and_read_cookiestxt
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
    jar.add(url, cookie)
    jar.add(url, cookie_from_hash(values.merge( :name => 'Baz' )))
    assert_equal(2, jar.cookies(url).length)

    jar.save_as("cookies.txt", :cookiestxt)
    jar.clear!
    assert_equal(0, jar.cookies(url).length)

    jar.load("cookies.txt", :cookiestxt)
    assert_equal(2, jar.cookies(url).length)

    FileUtils.rm("cookies.txt")
  end

  def test_ssl_cookies
    # thanks to michal "ocher" ochman for reporting the bug responsible for this test.
    values = {  :name     => 'Foo',
      :value    => 'Bar',
      :path     => '/login',
      :expires  => nil,
      :domain   => 'rubyforge.org'
    }
    values_ssl = {  :name     => 'Foo',
      :value    => 'Bar',
      :path     => '/login',
      :expires  => nil,
      :domain   => 'rubyforge.org:443'
    }
    url = URI.parse('https://rubyforge.org/login')

    jar = WWW::Mechanize::CookieJar.new
    assert_equal(0, jar.cookies(url).length)

    cookie = cookie_from_hash(values)
    jar.add(url, cookie)
    assert_equal(1, jar.cookies(url).length, "did not handle SSL cookie")

    cookie = cookie_from_hash(values_ssl)
    jar.add(url, cookie)
    assert_equal(2, jar.cookies(url).length, "did not handle SSL cookie with :443")
  end

end
