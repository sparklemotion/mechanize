require 'time'
require 'webrick/cookie'

# This class is used to represent an HTTP Cookie.
class Mechanize::Cookie < WEBrick::Cookie

  attr_accessor :session

  class << self
    def parse(uri, str, log = Mechanize.log)
      return str.split(/,(?=[^;,]*=)|,$/).map { |c|
        cookie_elem = c.split(/;+/)
        first_elem = cookie_elem.shift
        first_elem.strip!
        key, value = first_elem.split(/\=/, 2)

        cookie = nil
        begin
          cookie = new(key, value.dup)
        rescue
          log.warn("Couldn't parse key/value: #{first_elem}") if log
        end

        next unless cookie

        cookie_elem.each do |pair|
          pair.strip!
          key, value = pair.split(/\=/, 2)
          next unless key
          value = WEBrick::HTTPUtils.dequote(value.strip) if value

          case key.downcase
          when "domain" then
            value = ".#{value}" unless value =~ /^\./
            cookie.domain = value
          when "path" then
            cookie.path = value
          when 'expires'
            if value.empty? then
              cookie.session = true
              next
            end

            begin
              cookie.expires = Time::parse(value)
            rescue
              log.warn("Couldn't parse expires: #{value}") if log
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
        end

        cookie.path    ||= uri.path.to_s.sub(%r%[^/]*$%, '')
        cookie.secure  ||= false
        cookie.domain  ||= uri.host
        # Move this in to the cookie jar
        yield cookie if block_given?

        cookie
      }
    end
  end

  def expired?
    return false unless expires
    Time.now > expires
  end

  def to_s
    "#{@name}=#{@value}"
  end
end
