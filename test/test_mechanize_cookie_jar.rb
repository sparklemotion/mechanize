require 'mechanize/test_case'

class TestMechanizeCookieJar < Mechanize::TestCase

  def setup
    super

    @jar = Mechanize::CookieJar.new
    @tmpdir = Dir.mktmpdir

    @orig_dir = Dir.pwd
    Dir.chdir @tmpdir
  end

  def teardown
    Dir.chdir @orig_dir
    FileUtils.remove_entry_secure @tmpdir
  end

  def cookie_values(options = {})
    {
      :name     => 'Foo',
      :value    => 'Bar',
      :path     => '/',
      :expires  => Time.now + (10 * 86400),
      :for_domain => true,
      :domain   => 'rubyforge.org'
   }.merge(options)
  end

  def test_two_cookies_same_domain_and_name_different_paths
    url = URI.parse('http://rubyforge.org/')

    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:path => '/onetwo')))

    assert_equal(1, @jar.cookies(url).length)
    assert_equal 2, @jar.cookies(URI.parse('http://rubyforge.org/onetwo')).length
  end

  def test_domain_case
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    @jar.add(url, Mechanize::Cookie.new(
        cookie_values(:domain => 'RuByForge.Org', :name   => 'aaron')))

    assert_equal(2, @jar.cookies(url).length)

    url2 = URI.parse('http://RuByFoRgE.oRg/')
    assert_equal(2, @jar.cookies(url2).length)
  end

  def test_no_domain_case
    url = URI.parse('http://www.rubyforge.org/')

    @jar.add(url, Mechanize::Cookie.new(
        cookie_values(:domain => 'rubyforge.org', :for_domain => false)))

    assert_equal(0, @jar.cookies(url).length)
  end

  def test_empty_value
    values = cookie_values(:value => "")
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    @jar.add(url, Mechanize::Cookie.new( values.merge(  :domain => 'RuByForge.Org',
                                                  :name   => 'aaron'
                                               ) ) )

    assert_equal(2, @jar.cookies(url).length)

    url2 = URI.parse('http://RuByFoRgE.oRg/')
    assert_equal(2, @jar.cookies(url2).length)
  end

  def test_add_future_cookies
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    @jar.add(url, Mechanize::Cookie.new(cookie_values))
    assert_equal(1, @jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(1, @jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Make sure we can't get the cookie from different domains
    assert_equal(0, @jar.cookies(URI.parse('http://google.com/')).length)
  end

  def test_add_multiple_cookies
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    # Add the same cookie, and we should still only have one
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:name => 'Baz')))
    assert_equal(2, @jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, @jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Make sure we can't get the cookie from different domains
    assert_equal(0, @jar.cookies(URI.parse('http://google.com/')).length)
  end

  def test_add_rejects_cookies_that_do_not_contain_an_embedded_dot
    url = URI.parse('http://rubyforge.org/')

    tld_cookie = Mechanize::Cookie.new(cookie_values(:domain => '.org'))
    @jar.add(url, tld_cookie)
    single_dot_cookie = Mechanize::Cookie.new(cookie_values(:domain => '.'))
    @jar.add(url, single_dot_cookie)

    assert_equal(0, @jar.cookies(url).length)
  end

  def test_add_makes_exception_for_local_tld
    url = URI.parse('http://example.local')

    tld_cookie = Mechanize::Cookie.new(cookie_values(:domain => '.local'))
    @jar.add(url, tld_cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_add_makes_exception_for_localhost
    url = URI.parse('http://localhost')

    tld_cookie = Mechanize::Cookie.new(cookie_values(:domain => 'localhost'))
    @jar.add(url, tld_cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_add_cookie_for_the_parent_domain
    url = URI.parse('http://x.foo.com')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => '.foo.com'))
    @jar.add(url, cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_add_does_not_reject_cookies_from_a_nested_subdomain
    url = URI.parse('http://y.x.foo.com')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => '.foo.com'))
    @jar.add(url, cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_cookie_without_leading_dot_does_not_cause_substring_match
    url = URI.parse('http://arubyforge.org/')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => 'rubyforge.org'))
    @jar.add(url, cookie)

    assert_equal(0, @jar.cookies(url).length)
  end

  def test_cookie_without_leading_dot_matches_subdomains
    url = URI.parse('http://admin.rubyforge.org/')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => 'rubyforge.org'))
    @jar.add(url, cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_cookies_with_leading_dot_match_subdomains
    url = URI.parse('http://admin.rubyforge.org/')

    @jar.add(url, Mechanize::Cookie.new(cookie_values(:domain => '.rubyforge.org')))

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_cookies_with_leading_dot_match_parent_domains
    url = URI.parse('http://rubyforge.org/')

    @jar.add(url, Mechanize::Cookie.new(cookie_values(:domain => '.rubyforge.org')))

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_cookies_with_leading_dot_match_parent_domains_exactly
    url = URI.parse('http://arubyforge.org/')

    @jar.add(url, Mechanize::Cookie.new(cookie_values(:domain => '.rubyforge.org')))

    assert_equal(0, @jar.cookies(url).length)
  end

  def test_cookie_for_ipv4_address_matches_the_exact_ipaddress
    url = URI.parse('http://192.168.0.1/')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => '192.168.0.1'))
    @jar.add(url, cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_cookie_for_ipv4_address_does_not_cause_subdomain_match
    url = URI.parse('http://192.168.0.1/')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => '.0.1'))
    @jar.add(url, cookie)

    assert_equal(0, @jar.cookies(url).length)
  end

  def test_cookie_for_ipv6_address_matches_the_exact_ipaddress
    url = URI.parse('http://[fe80::0123:4567:89ab:cdef]/')

    cookie = Mechanize::Cookie.new(cookie_values(:domain => '[fe80::0123:4567:89ab:cdef]'))
    @jar.add(url, cookie)

    assert_equal(1, @jar.cookies(url).length)
  end

  def test_cookies_dot
    url = URI.parse('http://www.host.example/')

    @jar.add(url,
             Mechanize::Cookie.new(cookie_values(:domain => 'www.host.example')))

    url = URI.parse('http://wwwxhost.example/')
    assert_equal(0, @jar.cookies(url).length)
  end

  def test_clear_bang
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:name => 'Baz')))
    assert_equal(2, @jar.cookies(url).length)

    @jar.clear!

    assert_equal(0, @jar.cookies(url).length)
  end

  def test_save_cookies_yaml
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    s_cookie = Mechanize::Cookie.new(cookie_values(:name => 'Bar',
                                              :expires => nil,
                                              :session => true))

    @jar.add(url, cookie)
    @jar.add(url, s_cookie)
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:name => 'Baz')))

    assert_equal(3, @jar.cookies(url).length)

    @jar.save_as("cookies.yml")

    jar = Mechanize::CookieJar.new
    jar.load("cookies.yml")
    assert_equal(2, jar.cookies(url).length)

    assert_equal(3, @jar.cookies(url).length)
  end

  def test_save_cookies_cookiestxt
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    s_cookie = Mechanize::Cookie.new(cookie_values(:name => 'Bar',
                                              :expires => nil,
                                              :session => true))

    @jar.add(url, cookie)
    @jar.add(url, s_cookie)
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:name => 'Baz')))

    assert_equal(3, @jar.cookies(url).length)

    @jar.save_as("cookies.txt", :cookiestxt)

    jar = Mechanize::CookieJar.new
    jar.load("cookies.txt", :cookiestxt) # HACK test the format
    assert_equal(2, jar.cookies(url).length)

    assert_equal(3, @jar.cookies(url).length)
  end

  def test_expire_cookies
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    # Add a second cookie
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:name => 'Baz')))
    assert_equal(2, @jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, @jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    @jar.add(url, Mechanize::Cookie.new(
        cookie_values(:expires => Time.now - (10 * 86400))))
    assert_equal(1, @jar.cookies(url).length)

    # Expire the second cookie
    @jar.add(url, Mechanize::Cookie.new(
        cookie_values( :name => 'Baz', :expires => Time.now - (10 * 86400))))
    assert_equal(0, @jar.cookies(url).length)
  end

  def test_session_cookies
    values = cookie_values(:expires => nil)
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    # Add a second cookie
    @jar.add(url, Mechanize::Cookie.new(values.merge(:name => 'Baz')))
    assert_equal(2, @jar.cookies(url).length)

    # Make sure we can get the cookie from different paths
    assert_equal(2, @jar.cookies(URI.parse('http://rubyforge.org/login')).length)

    # Expire the first cookie
    @jar.add(url, Mechanize::Cookie.new(values.merge(:expires => Time.now - (10 * 86400))))
    assert_equal(1, @jar.cookies(url).length)

    # Expire the second cookie
    @jar.add(url, Mechanize::Cookie.new(
        values.merge(:name => 'Baz', :expires => Time.now - (10 * 86400))))
    assert_equal(0, @jar.cookies(url).length)

    # When given a URI with a blank path, CookieJar#cookies should return
    # cookies with the path '/':
    url = URI.parse('http://rubyforge.org')
    assert_equal '', url.path
    assert_equal(0, @jar.cookies(url).length)
    # Now add a cookie with the path set to '/':
    @jar.add(url, Mechanize::Cookie.new(values.merge( :name => 'has_root_path',
                                          :path => '/')))
    assert_equal(1, @jar.cookies(url).length)
  end

  def test_paths
    values = cookie_values(:path => "/login", :expires => nil)
    url = URI.parse('http://rubyforge.org/login')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length)

    # Add a second cookie
    @jar.add(url, Mechanize::Cookie.new(values.merge( :name => 'Baz' )))
    assert_equal(2, @jar.cookies(url).length)

    # Make sure we don't get the cookie in a different path
    assert_equal(0, @jar.cookies(URI.parse('http://rubyforge.org/hello')).length)
    assert_equal(0, @jar.cookies(URI.parse('http://rubyforge.org/')).length)

    # Expire the first cookie
    @jar.add(url, Mechanize::Cookie.new(values.merge( :expires => Time.now - (10 * 86400))))
    assert_equal(1, @jar.cookies(url).length)

    # Expire the second cookie
    @jar.add(url, Mechanize::Cookie.new(values.merge( :name => 'Baz',
                                          :expires => Time.now - (10 * 86400))))
    assert_equal(0, @jar.cookies(url).length)
  end

  def test_save_and_read_cookiestxt
    url = URI.parse('http://rubyforge.org/')

    # Add one cookie with an expiration date in the future
    cookie = Mechanize::Cookie.new(cookie_values)
    @jar.add(url, cookie)
    @jar.add(url, Mechanize::Cookie.new(cookie_values(:name => 'Baz')))
    assert_equal(2, @jar.cookies(url).length)

    @jar.save_as("cookies.txt", :cookiestxt)
    @jar.clear!

    @jar.load("cookies.txt", :cookiestxt)
    assert_equal(2, @jar.cookies(url).length)
  end

  def test_save_and_read_cookiestxt_with_session_cookies
    url = URI.parse('http://rubyforge.org/')

    @jar.add(url, Mechanize::Cookie.new(cookie_values(:expires => nil)))
    @jar.save_as("cookies.txt", :cookiestxt)
    @jar.clear!

    @jar.load("cookies.txt", :cookiestxt)
    assert_equal(1, @jar.cookies(url).length)
    assert_nil @jar.cookies(url).first.expires
  end

  def test_save_and_read_expired_cookies
    url = URI.parse('http://rubyforge.org/')

    @jar.jar['rubyforge.org'] = {}


    @jar.add url, Mechanize::Cookie.new(cookie_values)

    # HACK no asertion
  end

  def test_ssl_cookies
    # thanks to michal "ocher" ochman for reporting the bug responsible for this test.
    values = cookie_values(:expires => nil)
    values_ssl = values.merge(:name => 'Baz', :domain => "#{values[:domain]}:443")
    url = URI.parse('https://rubyforge.org/login')

    cookie = Mechanize::Cookie.new(values)
    @jar.add(url, cookie)
    assert_equal(1, @jar.cookies(url).length, "did not handle SSL cookie")

    cookie = Mechanize::Cookie.new(values_ssl)
    @jar.add(url, cookie)
    assert_equal(2, @jar.cookies(url).length, "did not handle SSL cookie with :443")
  end

  def test_secure_cookie
    nurl  = URI.parse('http://rubyforge.org/login')
    surl = URI.parse('https://rubyforge.org/login')

    ncookie = Mechanize::Cookie.new(cookie_values(:name => 'Foo1'))
    scookie = Mechanize::Cookie.new(cookie_values(:name => 'Foo2', :secure => true))

    @jar.add(nurl, ncookie)
    @jar.add(nurl, scookie)
    @jar.add(surl, ncookie)
    @jar.add(surl, scookie)

    assert_equal('Foo1',      @jar.cookies(nurl).map { |c| c.name }.sort.join(' ') )
    assert_equal('Foo1 Foo2', @jar.cookies(surl).map { |c| c.name }.sort.join(' ') )
  end
end
