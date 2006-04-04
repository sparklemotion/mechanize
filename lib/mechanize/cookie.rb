module WWW
  class Cookie
    attr_reader :name, :value, :path, :domain, :expires, :secure
    def initialize(url, cookie_text)
      cookie = Hash.new
      cookie_text.split(/; /).each do |data|
        name, value = data.split('=', 2)
        next unless name
        cookie[name] = value ? URI::unescape(value) : nil
      end
  
      @path = cookie.delete(
        cookie.keys.find { |k| k.downcase  == "path" }
      ) || url.path

      expires_key = cookie.keys.find { |k| k.downcase == "expires" }
      if expires_key
        @expires = DateTime.parse(cookie.delete(expires_key))
      end

      secure_key = cookie.keys.find { |k| k.downcase == "secure" }
      if secure_key
        @secure = true
        cookie.delete(secure_key)
      else
        @secure = false
      end
  
      # Set the domain name of the cookie
      domain_key = cookie.keys.find { |k| k.downcase == "domain" }
      if domain_key
        domain = cookie.delete(domain_key)
        domain.sub!(/^\./, '')
        if url.host =~ /#{domain}$/
          @domain = domain
        end
      else
        @domain = url.host
      end
  
      cookie.each { |k,v|
        @name = k.strip
        @value = v.strip
        @string = "#{k}=#{URI::escape(v)}"
      }
    end
  
    def Cookie::parse(uri, raw_cookie, &block)
      esc = raw_cookie.gsub(/(expires=[^,]*),([^;]*(;|$))/i) { "#{$1}#{$2}" }
      esc.split(/,/).each do |cookie|
        yield Cookie.new(uri, cookie)
      end
    end
  
    def to_s
      @string
    end
  end

  class CookieJar
    attr_accessor :jar
    def initialize
      @jar = {}
    end
  
    def add(cookie)
      unless @jar.has_key?(cookie.domain)
        @jar[cookie.domain] = Hash.new
      end
  
      @jar[cookie.domain][cookie.name] = cookie
    end
  
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
