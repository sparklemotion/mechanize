require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

module Enumerable
  def combine
    masks = inject([[], 1]){|(ar, m), e| [ar << m, m << 1 ] }[0]
    all = masks.inject(0){ |al, m| al|m }

    result = []
    for i in 1..all do
      tmp = []
      each_with_index do |e, idx|
        tmp << e unless (masks[idx] & i) == 0
      end
      result << tmp
    end
    result
  end
end

class CookieClassTest < Test::Unit::TestCase
  def silently
    warn_level = $VERBOSE
    $VERBOSE = false
    res = yield
    $VERBOSE = warn_level
    res
  end

  def test_parse_dates
    url = URI.parse('http://localhost/')

    yesterday = Time.now - 86400

    dates = [ "14 Apr 89 03:20:12",
              "14 Apr 89 03:20 GMT",
              "Fri, 17 Mar 89 4:01:33",
              "Fri, 17 Mar 89 4:01 GMT",
              "Mon Jan 16 16:12 PDT 1989",
              "Mon Jan 16 16:12 +0130 1989",
              "6 May 1992 16:41-JST (Wednesday)",
              #"22-AUG-1993 10:59:12.82",
              "22-AUG-1993 10:59pm",
              "22-AUG-1993 12:59am",
              "22-AUG-1993 12:59 PM",
              #"Friday, August 04, 1995 3:54 PM",
              #"06/21/95 04:24:34 PM",
              #"20/06/95 21:07",
              "95-06-08 19:32:48 EDT",
    ]

    dates.each do |date|
      cookie = "PREF=1; expires=#{date}"
      silently do
        WWW::Mechanize::Cookie.parse(url, cookie) { |c|
          assert c.expires, "Tried parsing: #{date}"
          assert_equal(true, c.expires < yesterday)
        }
      end
    end
  end

  def test_parse_weird_cookie
    cookie = 'n/a, ASPSESSIONIDCSRRQDQR=FBLDGHPBNDJCPCGNCPAENELB; path=/'
    url = URI.parse('http://www.searchinnovation.com/')
    WWW::Mechanize::Cookie.parse(url, cookie) { |c|
      assert_equal('ASPSESSIONIDCSRRQDQR', c.name)
      assert_equal('FBLDGHPBNDJCPCGNCPAENELB', c.value)
    }
  end

  def test_double_semicolon
    double_semi = 'WSIDC=WEST;; domain=.williams-sonoma.com; path=/'
    url = URI.parse('http://williams-sonoma.com/')
    WWW::Mechanize::Cookie.parse(url, double_semi) { |cookie|
      assert_equal('WSIDC', cookie.name)
      assert_equal('WEST', cookie.value)
    }
  end

  def test_parse_bad_version
    bad_cookie = 'PRETANET=TGIAqbFXtt; Name=/PRETANET; Path=/; Version=1.2; Content-type=text/html; Domain=192.168.6.196; expires=Friday, 13-November-2026  23:01:46 GMT;'
    url = URI.parse('http://localhost/')
    WWW::Mechanize::Cookie.parse(url, bad_cookie) { |cookie|
      assert_nil(cookie.version)
    }
  end

  def test_parse_bad_max_age
    bad_cookie = 'PRETANET=TGIAqbFXtt; Name=/PRETANET; Path=/; Max-Age=1.2; Content-type=text/html; Domain=192.168.6.196; expires=Friday, 13-November-2026  23:01:46 GMT;'
    url = URI.parse('http://localhost/')
    WWW::Mechanize::Cookie.parse(url, bad_cookie) { |cookie|
      assert_nil(cookie.max_age)
    }
  end

  def test_parse_date_fail
    url = URI.parse('http://localhost/')

    dates = [ 
              "20/06/95 21:07",
    ]

    silently do
      dates.each do |date|
        cookie = "PREF=1; expires=#{date}"
        WWW::Mechanize::Cookie.parse(url, cookie) { |c|
          assert_equal(true, c.expires.nil?)
        }
      end
    end
  end

  def test_parse_valid_cookie
    url = URI.parse('http://rubyforge.org/')
    cookie_params = {}
    cookie_params['expires']   = 'expires=Sun, 27-Sep-2037 00:00:00 GMT'
    cookie_params['path']      = 'path=/'
    cookie_params['domain']    = 'domain=.rubyforge.org'
    cookie_params['httponly']  = 'HttpOnly'
    cookie_value = '12345%7D=ASDFWEE345%3DASda'

    expires = Time.parse('Sun, 27-Sep-2037 00:00:00 GMT')
    
    cookie_params.keys.combine.each do |c|
      cookie_text = "#{cookie_value}; "
      c.each_with_index do |key, idx|
        if idx == (c.length - 1)
          cookie_text << "#{cookie_params[key]}"
        else
          cookie_text << "#{cookie_params[key]}; "
        end
      end
      cookie = nil
      WWW::Mechanize::Cookie.parse(url, cookie_text) { |p_cookie| cookie = p_cookie }
      assert_not_nil(cookie)
      assert_equal('12345%7D=ASDFWEE345%3DASda', cookie.to_s)
      assert_equal('/', cookie.path)
      assert_equal('rubyforge.org', cookie.domain)

      # if expires was set, make sure we parsed it
      if c.find { |k| k == 'expires' }
        assert_equal(expires, cookie.expires)
      else
        assert_nil(cookie.expires)
      end
    end
  end

  def test_parse_valid_cookie_empty_value
    url = URI.parse('http://rubyforge.org/')
    cookie_params = {}
    cookie_params['expires']   = 'expires=Sun, 27-Sep-2037 00:00:00 GMT'
    cookie_params['path']      = 'path=/'
    cookie_params['domain']    = 'domain=.rubyforge.org'
    cookie_params['httponly']  = 'HttpOnly'
    cookie_value = '12345%7D='

    expires = Time.parse('Sun, 27-Sep-2037 00:00:00 GMT')
    
    cookie_params.keys.combine.each do |c|
      cookie_text = "#{cookie_value}; "
      c.each_with_index do |key, idx|
        if idx == (c.length - 1)
          cookie_text << "#{cookie_params[key]}"
        else
          cookie_text << "#{cookie_params[key]}; "
        end
      end
      cookie = nil
      WWW::Mechanize::Cookie.parse(url, cookie_text) { |p_cookie| cookie = p_cookie }
      assert_not_nil(cookie)
      assert_equal('12345%7D=', cookie.to_s)
      assert_equal('', cookie.value)
      assert_equal('/', cookie.path)
      assert_equal('rubyforge.org', cookie.domain)

      # if expires was set, make sure we parsed it
      if c.find { |k| k == 'expires' }
        assert_equal(expires, cookie.expires)
      else
        assert_nil(cookie.expires)
      end
    end
  end

  # If no path was given, use the one from the URL
  def test_cookie_using_url_path
    url = URI.parse('http://rubyforge.org/login.php')
    cookie_params = {}
    cookie_params['expires']   = 'expires=Sun, 27-Sep-2037 00:00:00 GMT'
    cookie_params['path']      = 'path=/'
    cookie_params['domain']    = 'domain=.rubyforge.org'
    cookie_params['httponly']  = 'HttpOnly'
    cookie_value = '12345%7D=ASDFWEE345%3DASda'

    expires = Time.parse('Sun, 27-Sep-2037 00:00:00 GMT')
    
    cookie_params.keys.combine.each do |c|
      next if c.find { |k| k == 'path' }
      cookie_text = "#{cookie_value}; "
      c.each_with_index do |key, idx|
        if idx == (c.length - 1)
          cookie_text << "#{cookie_params[key]}"
        else
          cookie_text << "#{cookie_params[key]}; "
        end
      end
      cookie = nil
      WWW::Mechanize::Cookie.parse(url, cookie_text) { |p_cookie| cookie = p_cookie }
      assert_not_nil(cookie)
      assert_equal('12345%7D=ASDFWEE345%3DASda', cookie.to_s)
      assert_equal('rubyforge.org', cookie.domain)
      assert_equal('/', cookie.path)

      # if expires was set, make sure we parsed it
      if c.find { |k| k == 'expires' }
        assert_equal(expires, cookie.expires)
      else
        assert_nil(cookie.expires)
      end
    end
  end

  # Test using secure cookies
  def test_cookie_with_secure
    url = URI.parse('http://rubyforge.org/')
    cookie_params = {}
    cookie_params['expires']   = 'expires=Sun, 27-Sep-2037 00:00:00 GMT'
    cookie_params['path']      = 'path=/'
    cookie_params['domain']    = 'domain=.rubyforge.org'
    cookie_params['secure']    = 'secure'
    cookie_value = '12345%7D=ASDFWEE345%3DASda'

    expires = Time.parse('Sun, 27-Sep-2037 00:00:00 GMT')
    
    cookie_params.keys.combine.each do |c|
      next unless c.find { |k| k == 'secure' }
      cookie_text = "#{cookie_value}; "
      c.each_with_index do |key, idx|
        if idx == (c.length - 1)
          cookie_text << "#{cookie_params[key]}"
        else
          cookie_text << "#{cookie_params[key]}; "
        end
      end
      cookie = nil
      WWW::Mechanize::Cookie.parse(url, cookie_text) { |p_cookie| cookie = p_cookie }
      assert_not_nil(cookie)
      assert_equal('12345%7D=ASDFWEE345%3DASda', cookie.to_s)
      assert_equal('rubyforge.org', cookie.domain)
      assert_equal('/', cookie.path)
      assert_equal(true, cookie.secure)

      # if expires was set, make sure we parsed it
      if c.find { |k| k == 'expires' }
        assert_equal(expires, cookie.expires)
      else
        assert_nil(cookie.expires)
      end
    end
  end

  # If no domain was given, we must use the one from the URL
  def test_cookie_with_url_domain
    url = URI.parse('http://login.rubyforge.org/')
    cookie_params = {}
    cookie_params['expires']   = 'expires=Sun, 27-Sep-2037 00:00:00 GMT'
    cookie_params['path']      = 'path=/'
    cookie_params['domain']    = 'domain=.rubyforge.org'
    cookie_params['httponly']  = 'HttpOnly'
    cookie_value = '12345%7D=ASDFWEE345%3DASda'

    expires = Time.parse('Sun, 27-Sep-2037 00:00:00 GMT')
    
    cookie_params.keys.combine.each do |c|
      next if c.find { |k| k == 'domain' }
      cookie_text = "#{cookie_value}; "
      c.each_with_index do |key, idx|
        if idx == (c.length - 1)
          cookie_text << "#{cookie_params[key]}"
        else
          cookie_text << "#{cookie_params[key]}; "
        end
      end
      cookie = nil
      WWW::Mechanize::Cookie.parse(url, cookie_text) { |p_cookie| cookie = p_cookie }
      assert_not_nil(cookie)
      assert_equal('12345%7D=ASDFWEE345%3DASda', cookie.to_s)
      assert_equal('/', cookie.path)

      assert_equal('login.rubyforge.org', cookie.domain)

      # if expires was set, make sure we parsed it
      if c.find { |k| k == 'expires' }
        assert_equal(expires, cookie.expires)
      else
        assert_nil(cookie.expires)
      end
    end
  end

  def test_parse_cookie_no_spaces
    url = URI.parse('http://rubyforge.org/')
    cookie_params = {}
    cookie_params['expires']   = 'expires=Sun, 27-Sep-2037 00:00:00 GMT'
    cookie_params['path']      = 'path=/'
    cookie_params['domain']    = 'domain=.rubyforge.org'
    cookie_params['httponly']  = 'HttpOnly'
    cookie_value = '12345%7D=ASDFWEE345%3DASda'

    expires = Time.parse('Sun, 27-Sep-2037 00:00:00 GMT')
    
    cookie_params.keys.combine.each do |c|
      cookie_text = "#{cookie_value};"
      c.each_with_index do |key, idx|
        if idx == (c.length - 1)
          cookie_text << "#{cookie_params[key]}"
        else
          cookie_text << "#{cookie_params[key]};"
        end
      end
      cookie = nil
      WWW::Mechanize::Cookie.parse(url, cookie_text) { |p_cookie| cookie = p_cookie }
      assert_not_nil(cookie)
      assert_equal('12345%7D=ASDFWEE345%3DASda', cookie.to_s)
      assert_equal('/', cookie.path)
      assert_equal('rubyforge.org', cookie.domain)

      # if expires was set, make sure we parsed it
      if c.find { |k| k == 'expires' }
        assert_equal(expires, cookie.expires)
      else
        assert_nil(cookie.expires)
      end
    end
  end
end

