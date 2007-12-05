require 'yaml'
require 'time'
require 'webrick/cookie'

module WWW
  class Mechanize
  # This class is used to represent an HTTP Cookie.
    class Cookie < WEBrick::Cookie
      def self.parse(uri, str, log = nil)
        return str.split(/,(?=[^;,]*=)|,$/).collect { |c|
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
              begin
                cookie.expires = Time::parse(value)
              rescue
                if log
                  log.warn("Couldn't parse expires: #{value}")
                end
              end
            when "max-age" then
              begin
                cookie.max_age = Integer(value)
              rescue
                log.warn("Couldn't parse max age '#{value}'") if log
                cookie.max_age = nil
              end
            when "comment" then cookie.comment = value
            when "version" then
              begin
                cookie.version = Integer(value)
              rescue
                log.warn("Couldn't parse version '#{value}'") if log
                cookie.version = nil
              end
            when "secure"  then cookie.secure = true
            end
          }

          cookie.path    ||= uri.path.to_s.sub(/[^\/]*$/, '')
          cookie.secure  ||= false
          cookie.domain  ||= uri.host
          # Move this in to the cookie jar
          yield cookie if block_given?
        }
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
        return unless uri.host =~ /#{cookie.domain}$/i
        normal_domain = cookie.domain.downcase
        unless @jar.has_key?(normal_domain)
          @jar[normal_domain] = Hash.new
        end
    
        @jar[normal_domain][cookie.name] = cookie
        cleanup()
        cookie
      end
    
      # Fetch the cookies that should be used for the URI object passed in.
      def cookies(url)
        cleanup
        cookies = []
        url.path = '/' if url.path.empty?
        @jar.each_key do |domain|
          if url.host =~ /#{domain}$/i
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
