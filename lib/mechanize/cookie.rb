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
      end
    
      def Cookie::parse(uri, raw_cookie, &block)
        esc = raw_cookie.gsub(/(expires=[^,]*),([^;]*(;|$))/i) { "#{$1}#{$2}" }
        esc.split(/,/).each do |cookie_text|
          cookie = Hash.new
          valid_cookie = true
          cookie_text.split(/; ?/).each do |data|
            name, value = data.split('=', 2)
            next unless name

            name.strip!
    
            # Set the cookie to invalid if the domain is incorrect
            case name.downcase
            when 'path'
              cookie[:path] = value
            when 'expires'
              cookie[:expires] = begin
                Time::parse(value)
              rescue
                Time.now
              end
            when 'secure'
              cookie[:secure] = true
            when 'domain' # Reject the cookie if it isn't for this domain
              cookie[:domain] = value.sub(/^\./, '')

              # Reject cookies not for this domain
              # TODO Move the logic to reject based on host to the jar
              unless uri.host =~ /#{cookie[:domain]}$/
                valid_cookie = false
              end
            when 'httponly'
              # do nothing
          # http://msdn.microsoft.com/workshop/author/dhtml/httponly_cookies.asp
            else
              cookie[:name]  = name
              cookie[:value] = value
            end
          end

          # Don't yield this cookie if it is invalid
          next unless valid_cookie

          cookie[:path]    ||= uri.path
          cookie[:secure]  ||= false
          cookie[:domain]  ||= uri.host

          yield Cookie.new(cookie)
        end
      end
    
      def to_s
        "#{@name}=#{@value}"
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
