require 'time'
require 'webrick/cookie'

module WWW
  class Mechanize
  # This class is used to represent an HTTP Cookie.
    class Cookie < WEBrick::Cookie
      def self.parse(uri, str, log = Mechanize.log)
        return str.split(/,(?=[^;,]*=)|,$/).collect { |c|
          cookie_elem = c.split(/;+/)
          first_elem = cookie_elem.shift
          first_elem.strip!
          key, value = first_elem.split(/=/, 2)

          cookie = nil
          begin
            cookie = new(key, WEBrick::HTTPUtils.dequote(value))
          rescue
            log.warn("Couldn't parse key/value: #{first_elem}") if log
          end
          next unless cookie

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
  end
end
