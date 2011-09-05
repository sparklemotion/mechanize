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

        cookie.path    ||= (uri + './').path
        cookie.secure  ||= false
        cookie.domain  ||= uri.host
        # Move this in to the cookie jar
        yield cookie if block_given?

        cookie
      }
    end

    def normalize_domain(domain)
      # RFC 6265 #4.1.2.3
      return nil if domain.end_with?('.')
      domain.downcase.tap { |dom|
        dom.sub!(/:[0-9]+$/,'')
        dom.sub!(/^\./,'')
      }
    end
  end

  alias set_domain domain=
  def domain=(domain)
    set_domain(self.class.normalize_domain(domain))
  end

  def expired?
    return false unless expires
    Time.now > expires
  end

  alias secure? secure

  def acceptable_from_uri?(uri)
    dom = domain or return false
    host = self.class.normalize_domain(uri.host)

    return true if host == dom
    return false if dom.match(/^(?!local)[^.]+$/)
    return host.end_with?('.' << dom)
  end

  def valid_for_uri?(uri)
    acceptable_from_uri?(uri) && uri.path.start_with?(path)
  end

  def to_s
    "#{@name}=#{@value}"
  end
end
