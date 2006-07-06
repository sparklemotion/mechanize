require 'yaml'
require 'time'

module WWW
  class Mechanize
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
            cookie.keys.find { |k| k.downcase  == "path" } ) || uri.path

          expires_key = cookie.keys.find { |k| k.downcase == "expires" }
          if expires_key
            time = nil
            expires_val = cookie.delete(expires_key)

            # If we can't parse the time, set it to the current time
            begin
              time = Time::parse(expires_val)
            rescue
              time = Time.now
            end

            # If we couldn't parse it, set it to the current time
            time = Time.now if time == nil
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
      attr_reader :jar

      def initialize
        @jar = {}
      end
    
      # Add a cookie to the Jar.
      def add(cookie)
        unless @jar.has_key?(cookie.domain)
          @jar[cookie.domain] = Hash.new
        end
    
        @jar[cookie.domain][cookie.name] = cookie
        cleanup()
        cookie
      end
    
      # Fetch the cookies that should be used for the URI object passed in.
      def cookies(url)
        cleanup
        cookies = []
        url.path = '/' if url.path.empty?
        @jar.each_key do |domain|
          if url.host =~ /#{domain}$/
            @jar[domain].each_key do |name|
              if url.path =~ /^#{@jar[domain][name].path}/
                if @jar[domain][name].expires.nil?
                  cookies << @jar[domain][name]
                elsif Time.now < @jar[domain][name].expires
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

      def to_a
        cookies = []
        @jar.each_key do |domain|
          @jar[domain].each_key do |name|
            cookies << @jar[domain][name]
          end
        end
        cookies
      end

      # Save the cookie jar to a file as YAML
      def save_as(file)
        ::File.open(file, "w") { |f|
          YAML::dump(@jar, f)
        }
      end

      # Load cookie jar from a file stored as YAML
      def load(file)
        @jar = ::File.open(file) { |yf| YAML::load( yf ) }
      end

      # Clear the cookie jar
      def clear!
        @jar = {}
      end

      private
      # Remove expired cookies
      def cleanup
        @jar.each_key do |domain|
          @jar[domain].each_key do |name|
            unless @jar[domain][name].expires.nil?
              if Time.now > @jar[domain][name].expires
                @jar[domain].delete(name)
              end
            end
          end
        end
      end
    end
  end
end
