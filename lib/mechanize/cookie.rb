require 'date'

module WWW
  # This class is used to represent an HTTP Cookie.
  class Cookie
    attr_reader :name, :value, :path, :domain, :expires, :secure
    def initialize(cookie)
      @name     = cookie[:name]
      @value    = cookie[:value]
      @path     = cookie[:path]
      @domain   = cookie[:domain]
      @expires  = cookie[:expires]
      @secure   = cookie[:secure]
      @string   = "#{cookie[:name]}=#{cookie[:value]}"
    end
  
    def Cookie::parse(uri, raw_cookie, &block)
      esc = raw_cookie.gsub(/(expires=[^,]*),([^;]*(;|$))/i) { "#{$1}#{$2}" }
      esc.split(/,/).each do |cookie_text|
        cookie_values = Hash.new
        cookie = Hash.new
        cookie_text.split(/; ?/).each do |data|
          name, value = data.split('=', 2)
          next unless name
          cookie[name.strip] = value
        end
  
        cookie_values[:path] = cookie.delete(
          cookie.keys.find { |k| k.downcase  == "path" }
        ) || uri.path

        expires_key = cookie.keys.find { |k| k.downcase == "expires" }
        if expires_key
          time = nil
          expires_val = cookie.delete(expires_key)

          # First lets try dates with timezones
          [ '%A %d-%b-%y %T %Z',
            '%a %d-%b-%Y %T %Z',
            '%a %d %b %Y %T %Z',
            '%d %b %y %H:%M %Z',      # 14 Apr 89 03:20 GMT
            '%a %d %b %y %H:%M %Z',   # Fri, 17 Mar 89 4:01 GMT
            '%a %b %d %H:%M %Z %Y',   # Mon Jan 16 16:12 PDT 1989
            '%d %b %Y %H:%M-%Z (%A)', # 6 May 1992 16:41-JST (Wednesday)
            '%y-%m-%d %T %Z',         # 95-06-08 19:32:48 EDT
          ].each { |fmt|
            begin
              time = DateTime.strptime(expires_val, fmt)
            rescue ArgumentError => er
            else
              break
            end
          }

          # If it didn't have a timezone, we'll assume GMT, like Mozilla does
          if time.nil?
            [
              '%d %b %y %T %Z',            # 14 Apr 89 03:20:12
              '%a %d %b %y %T %Z',         # Fri, 17 Mar 89 4:01:33
              #'%d-%b-%Y %H:%M:%S.%N %Z',   # 22-AUG-1993 10:59:12.82
              '%d-%b-%Y %H:%M%P %Z',       # 22-AUG-1993 10:59pm
              '%d-%b-%Y %H:%M %p %Z',      # 22-AUG-1993 12:59 PM
              #'%A %B %d %Y %H:%M %p',   # Friday, August 04, 1995 3:54 PM
              '%x %I:%M:%S %p %Z',         # 06/21/95 04:24:34 PM
              '%d/%m/%y %H:%M %Z',         # 20/06/95 21:07
            ].each { |fmt|
              begin
                time = DateTime.strptime("#{expires_val} GMT", fmt)
              rescue ArgumentError => er
              else
                break
              end
            }
          end

          # If we couldn't parse it, set it to the current time
          time = DateTime.now if time == nil
          cookie_values[:expires] = time
        end

        secure_key = cookie.keys.find { |k| k.downcase == "secure" }
        if secure_key
          cookie_values[:secure] = true
          cookie.delete(secure_key)
        else
          cookie_values[:secure] = false
        end
  
        # Set the domain name of the cookie
        domain_key = cookie.keys.find { |k| k.downcase == "domain" }
        if domain_key
          domain = cookie.delete(domain_key)
          domain.sub!(/^\./, '')

          # Reject cookies not for this domain
          next unless uri.host =~ /#{domain}$/
          cookie_values[:domain] = domain
        else
          cookie_values[:domain] = uri.host
        end

        # Delete the http only option
        # http://msdn.microsoft.com/workshop/author/dhtml/httponly_cookies.asp
        http_only = cookie.keys.find { |k| k.downcase == 'httponly' }
        cookie.delete(http_only) if http_only

        cookie.each { |k,v|
          cookie_values[:name] = k.strip
          cookie_values[:value] = v.strip
        }
        yield Cookie.new(cookie_values)
      end
    end
  
    def to_s
      @string
    end
  end

  # This class is used to manage the Cookies that have been returned from
  # any particular website.
  class CookieJar
    attr_accessor :jar
    def initialize
      @jar = {}
    end
  
    # Add a cookie to the Jar.
    def add(cookie)
      unless @jar.has_key?(cookie.domain)
        @jar[cookie.domain] = Hash.new
      end
  
      @jar[cookie.domain][cookie.name] = cookie
    end
  
    # Fetch the cookies that should be used for the URI object passed in.
    def cookies(url)
      cookies = []
      @jar.each_key do |domain|
        if url.host =~ /#{domain}$/
          @jar[domain].each_key do |name|
            if url.path =~ /^#{@jar[domain][name].path}/
              if @jar[domain][name].expires.nil?
                cookies << @jar[domain][name]
              elsif DateTime.now < @jar[domain][name].expires
                cookies << @jar[domain][name]
              end
            end
          end
        end
      end
  
      cookies
    end
  
    def empty?(url)
      cookies(url).length > 0 ? false : true
    end
  end
end
