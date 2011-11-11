require 'time'
require 'webrick/cookie'
require 'domain_name'

# This class is used to represent an HTTP Cookie.
class Mechanize::Cookie
  attr_reader :name
  attr_accessor :value, :version
  attr_accessor :domain, :path, :secure
  attr_accessor :comment, :max_age

  attr_accessor :session

  attr_accessor :created_at
  attr_accessor :accessed_at

  # :call-seq:
  #     new(name, value)
  #     new(name, value, attr_hash)
  #     new(attr_hash)
  #
  # Creates a cookie object.  For each key of +attr_hash+, the setter
  # is called if defined.  Each key can be either a symbol or a
  # string, downcased or not.
  #
  # e.g.
  #     new("uid", "a12345")
  #     new("uid", "a12345", :domain => 'example.org',
  #                          :for_domain => true, :expired => Time.now + 7*86400)
  #     new("name" => "uid", "value" => "a12345", "Domain" => 'www.example.org')
  #
  def initialize(*args)
    @version = 0     # Netscape Cookie

    @domain = @path = @secure = @comment = @max_age =
      @expires = @comment_url = @discard = @port = nil

    @created_at = @accessed_at = Time.now
    case args.size
    when 2
      @name, @value = *args
      @for_domain = false
      return
    when 3
      @name, @value, attr_hash = *args
    when 1
      attr_hash = args.first
    else
      raise ArgumentError, "wrong number of arguments (#{args.size} for 1-3)"
    end
    for_domain = false
    attr_hash.each_pair { |key, val|
      skey = key.to_s.downcase
      skey.sub!(/[!?]\z/, '')
      case skey
      when 'for_domain'
        for_domain = !!val
      when 'name'
        @name = val
      when 'value'
        @value = val
      else
        setter = :"#{skey}="
        send(setter, val) if respond_to?(setter)
      end
    }
    @for_domain = for_domain
  end

  # If this flag is true, this cookie will be sent to any host in the
  # +domain+.  If it is false, this cookie will be sent only to the
  # host indicated by the +domain+.
  attr_accessor :for_domain
  alias for_domain? for_domain

  class << self
    # Parses a Set-Cookie header line +str+ sent from +uri+ into an
    # array of Cookie objects.  Note that this array may contain
    # nil's when some of the cookie-pairs are malformed.
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
            begin
              cookie.domain = value
              cookie.for_domain = true
            rescue
              log.warn("Couldn't parse domain: #{value}") if log
            end
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
  end

  alias set_domain domain=

  # Sets the domain attribute.  A leading dot in +domain+ implies
  # turning the +for_domain?+ flag on.
  def domain=(domain)
    if DomainName === domain
      @domain_name = domain
    else
      domain.is_a?(String) or
        (domain.respond_to?(:to_str) && (domain = domain.to_str).is_a?(String)) or
        raise TypeError, "#{domain.class} is not a String"
      if domain.start_with?('.')
        @for_domain = true
        domain = domain[1..-1]
      end
      # Do we really need to support this?
      if domain.match(/\A([^:]+):[0-9]+\z/)
        domain = $1
      end
      @domain_name = DomainName.new(domain)
    end
    set_domain(@domain_name.hostname)
  end

  def expires=(t)
    @expires = t && (t.is_a?(Time) ? t.httpdate : t.to_s)
  end

  def expires
    @expires && Time.parse(@expires)
  end

  def expired?
    return false unless expires
    Time.now > expires
  end

  alias secure? secure

  def acceptable_from_uri?(uri)
    host = DomainName.new(uri.host)

    # RFC 6265 5.3
    # When the user agent "receives a cookie":
    return host.hostname == domain unless @for_domain

    if host.cookie_domain?(@domain_name)
      true
    elsif host.hostname == domain
      @for_domain = false
      true
    else
      false
    end
  end

  def valid_for_uri?(uri)
    return false if secure? && uri.scheme != 'https'
    acceptable_from_uri?(uri) && uri.path.start_with?(path)
  end

  def to_s
    "#{@name}=#{@value}"
  end

  def init_with(coder)
    yaml_initialize(coder.tag, coder.map)
  end

  def yaml_initialize(tag, map)
    @for_domain = true    # for forward compatibility
    map.each { |key, value|
      case key
      when 'domain'
        self.domain = value # ditto
      else
        instance_variable_set(:"@#{key}", value)
      end
    }
  end
end
