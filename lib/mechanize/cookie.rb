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

        begin
          cookie = new(key, value.dup)
        rescue
          log.warn("Couldn't parse key/value: #{first_elem}") if log
          next
        end

        cookie_elem.each do |pair|
          pair.strip!
          key, value = pair.split(/\=/, 2)
          next unless key
          value = WEBrick::HTTPUtils.dequote(value.strip) if value

          case key.downcase
          when 'domain'
            cookie.domain = value
          when 'path'
            cookie.path = value
          when 'expires'
            if value.empty?
              cookie.session = true
              next
            end

            begin
              cookie.expires = Time::parse(value)
            rescue
              log.warn("Couldn't parse expires: #{value}") if log
            end
          when 'max-age'
            begin
              cookie.max_age = Integer(value)
            rescue
              log.warn("Couldn't parse max age '#{value}'") if log
            end
          when 'comment'
            cookie.comment = value
          when 'version'
            begin
              cookie.version = Integer(value)
            rescue
              log.warn("Couldn't parse version '#{value}'") if log
              cookie.version = nil
            end
          when 'secure'
            cookie.secure = true
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

    # RFC 6265 #5.1.3
    # Do not perform subdomain matching against IP addresses.
    return false if host.match(/^(?:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+|\[[0-9a-fA-F:]+\])$/)

    # RFC 6265 #4.1.1
    # Domain-value must be a subdomain.
    return false if dom.match(/^(?!local)[^.]+$/)
    # We exempt local* from this rule for testing purposes for now.

    return host.end_with?('.' << dom)
  end

  def valid_for_uri?(uri)
    return false if secure? && uri.scheme != 'https'
    acceptable_from_uri?(uri) && uri.path.start_with?(path)
  end

  def to_s
    "#{@name}=#{@value}"
  end
end
