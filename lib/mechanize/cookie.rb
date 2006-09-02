require 'yaml'
require 'time'
require 'webrick/httputils'
require 'webrick/cookie'

module WWW
  class Mechanize
  # This class is used to represent an HTTP Cookie.
    class Cookie < WEBrick::Cookie
      def self.parse(uri, str)
        cookies = []
        str.gsub(/(,([^;,]*=)|,$)/) { "\r\n#{$2}" }.split(/\r\n/).each { |c|
          cookie_elem = c.split(/;/)
          first_elem = cookie_elem.shift
          first_elem.strip!
          key, value = first_elem.split(/=/, 2)
          cookie = new(key, WEBrick::HTTPUtils.dequote(value))
          cookie_elem.each{|pair|
            pair.strip!
            key, value = pair.split(/=/, 2)
            if value
              value = WEBrick::HTTPUtils.dequote(value.strip)
            end
            case key.downcase
            when "domain"  then cookie.domain  = value.sub(/^\./, '')
            when "path"    then cookie.path    = value
            when 'expires'
              cookie.expires = begin
                Time::parse(value)
              rescue
                Time.now
              end
            when "max-age" then cookie.max_age = Integer(value)
            when "comment" then cookie.comment = value
            when "version" then cookie.version = Integer(value)
            when "secure"  then cookie.secure = true
            end
          }
          cookie.path    ||= uri.path
          cookie.secure  ||= false
          cookie.domain  ||= uri.host
          # Move this in to the cookie jar
          yield cookie if block_given?
          cookies << cookie
        }
        return cookies
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
      def add(uri, cookie)
        return unless uri.host =~ /#{cookie.domain}$/
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
