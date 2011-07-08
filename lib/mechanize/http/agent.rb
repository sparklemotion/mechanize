##
# An HTTP (and local disk access) user agent

class Mechanize::HTTP::Agent

  attr_accessor :cookie_jar

  # Disables If-Modified-Since conditional requests (enabled by default)
  attr_accessor :conditional_requests
  attr_accessor :context

  # Follow HTML meta refresh.  If set to +:anywhere+ meta refresh tags outside
  # of the head element will be followed.
  attr_accessor :follow_meta_refresh
  attr_accessor :gzip_enabled
  attr_accessor :history

  # Length of time to wait until a connection is opened in seconds
  attr_accessor :open_timeout

  attr_accessor :password
  attr_reader :proxy_uri

  # A list of hooks to call after retrieving a response.  Hooks are called with
  # the agent and the response returned.

  attr_reader :post_connect_hooks

  # A list of hooks to call before making a request.  Hooks are called with
  # the agent and the request to be performed.

  attr_reader :pre_connect_hooks

  # Length of time to attempt to read data from the server
  attr_accessor  :read_timeout

  # Controls how this agent deals with redirects.  The following values are
  # allowed:
  #
  # :all, true:: All 3xx redirects are followed (default)
  # :permanent:: Only 301 Moved Permanantly redirects are followed
  # false:: No redirects are followed

  attr_accessor :redirect_ok
  attr_accessor :redirection_limit

  # A hash of request headers to be used

  attr_accessor :request_headers

  # When true, this agent will consult the site's robots.txt for each access.

  attr_reader :robots

  attr_accessor :scheme_handlers

  attr_accessor :user
  attr_reader :user_agent

  # Path to an OpenSSL server certificate file
  attr_accessor :ca_file

  # An OpenSSL private key or the path to a private key
  attr_accessor :key

  # An OpenSSL client certificate or the path to a certificate file.
  attr_accessor :cert

  # OpenSSL key password
  attr_accessor :pass

  # A callback for additional certificate verification.  See
  # OpenSSL::SSL::SSLContext#verify_callback
  #
  # The callback can be used for debugging or to ignore errors by always
  # returning +true+.  Specifying nil uses the default method that was valid
  # when the SSLContext was created
  attr_accessor :verify_callback

  attr_reader :http # :nodoc:

  def initialize
    @auth_hash            = {} # Keep track of urls for sending auth
    @conditional_requests = true
    @context              = nil
    @cookie_jar           = Mechanize::CookieJar.new
    @digest               = nil # DigestAuth Digest
    @digest_auth          = Net::HTTP::DigestAuth.new
    @follow_meta_refresh  = false
    @gzip_enabled         = true
    @history              = Mechanize::History.new
    @keep_alive_time      = 300
    @open_timeout         = nil
    @password             = nil # HTTP auth password
    @post_connect_hooks   = []
    @pre_connect_hooks    = []
    @proxy_uri            = nil
    @read_timeout         = nil
    @redirect_ok          = true
    @redirection_limit    = 20
    @request_headers      = {}
    @robots               = false
    @user                 = nil # HTTP auth user
    @user_agent           = nil
    @webrobots            = nil

    @ca_file         = nil # OpenSSL server certificate file
    @cert            = nil # OpenSSL Certificate
    @key             = nil # OpenSSL Private Key
    @pass            = nil # OpenSSL Password
    @verify_callback = nil

    @scheme_handlers = Hash.new { |h, scheme|
      h[scheme] = lambda { |link, page|
        raise Mechanize::UnsupportedSchemeError, scheme
      }
    }

    @scheme_handlers['http']      = lambda { |link, page| link }
    @scheme_handlers['https']     = @scheme_handlers['http']
    @scheme_handlers['relative']  = @scheme_handlers['http']
    @scheme_handlers['file']      = @scheme_handlers['http']
  end

  # Equivalent to the browser back button.  Returns the most recent page
  # visited.
  def back
    @history.pop
  end

  def certificate
    @http.certificate
  end

  def connection_for uri
    case uri.scheme.downcase
    when 'http', 'https' then
      return @http
    when 'file' then
      return Mechanize::FileConnection.new
    end
  end

  ##
  # Returns the latest page loaded by the agent

  def current_page
    @history.last
  end

  def enable_gzip request
    request['accept-encoding'] = if @gzip_enabled
                                   'gzip,deflate,identity'
                                 else
                                   'identity'
                                 end
  end

  # uri is an absolute URI
  def fetch uri, method = :get, headers = {}, params = [],
            referer = current_page, redirects = 0
    referer_uri = referer ? referer.uri : nil

    uri = resolve uri, referer

    uri, params = resolve_parameters uri, method, params

    request = http_request uri, method, params

    connection = connection_for uri

    request_auth request, uri

    enable_gzip request

    request_language_charset request
    request_cookies request, uri
    request_host request, uri
    request_referer request, uri, referer_uri
    request_user_agent request
    request_add_headers request, headers

    pre_connect request

    # Consult robots.txt
    if robots && uri.is_a?(URI::HTTP)
      robots_allowed?(uri) or raise Mechanize::RobotsDisallowedError.new(uri)
    end

    # Add If-Modified-Since if page is in history
    if (page = visited_page(uri)) and page.response['Last-Modified']
      request['If-Modified-Since'] = page.response['Last-Modified']
    end if(@conditional_requests)

    # Specify timeouts if given
    connection.open_timeout = @open_timeout if @open_timeout
    connection.read_timeout = @read_timeout if @read_timeout

    request_log request

    response_body_io = nil

    # Send the request
    response = connection.request(uri, request) { |res|
      response_log res

      response_body_io = response_read res, request

      res
    }

    response_body = response_content_encoding response, response_body_io

    post_connect uri, response, response_body

    page = response_parse response, response_body, uri

    response_cookies response, uri, page

    meta = response_follow_meta_refresh response, uri, page, redirects
    return meta if meta

    case response
    when Net::HTTPSuccess
      if robots && page.is_a?(Mechanize::Page)
        page.parser.noindex? and raise Mechanize::RobotsDisallowedError.new(uri)
      end

      page
    when Mechanize::FileResponse
      page
    when Net::HTTPNotModified
      log.debug("Got cached page") if log
      visited_page(uri) || page
    when Net::HTTPRedirection
      response_redirect response, method, page, redirects
    when Net::HTTPUnauthorized
      response_authenticate(response, page, uri, request, headers, params,
                            referer)
    else
      raise Mechanize::ResponseCodeError.new(page), "Unhandled response"
    end
  end

  def max_history
    @history.max_size
  end

  def max_history=(length)
    @history.max_size = length
  end

  def http_request uri, method, params = nil
    case uri.scheme.downcase
    when 'http', 'https' then
      klass = Net::HTTP.const_get(method.to_s.capitalize)

      request ||= klass.new(uri.request_uri)
      request.body = params.first if params

      request
    when 'file' then
      Mechanize::FileRequest.new uri
    end
  end

  def log
    Mechanize.log
  end

  ##
  # Invokes hooks added to post_connect_hooks after a +response+ is returned
  # and the response +body+ is handled.
  #
  # Yields the +context+, the +uri+ for the request, the +response+ and the
  # response +body+.

  def post_connect uri, response, body # :yields: agent, uri, response, body
    @post_connect_hooks.each do |hook|
      hook.call self, uri, response, body
    end
  end

  ##
  # Invokes hooks added to pre_connect_hooks before a +request+ is made.
  # Yields the +agent+ and the +request+ that will be performed to each hook.

  def pre_connect request # :yields: agent, request
    @pre_connect_hooks.each do |hook|
      hook.call self, request
    end
  end

  def request_auth request, uri
    auth_type = @auth_hash[uri.host]

    return unless auth_type

    case auth_type
    when :basic
      request.basic_auth @user, @password
    when :digest, :iis_digest
      uri.user = @user
      uri.password = @password

      iis = auth_type == :iis_digest

      auth = @digest_auth.auth_header uri, @digest, request.method, iis

      request['Authorization'] = auth
    end
  end

  def request_cookies request, uri
    return if @cookie_jar.empty? uri

    cookies = @cookie_jar.cookies uri

    return if cookies.empty?

    request.add_field 'Cookie', cookies.join('; ')
  end

  def request_host request, uri
    port = [80, 443].include?(uri.port.to_i) ? nil : uri.port
    host = uri.host

    request['Host'] = [host, port].compact.join ':'
  end

  def request_language_charset request
    request['accept-charset']  = 'ISO-8859-1,utf-8;q=0.7,*;q=0.7'
    request['accept-language'] = 'en-us,en;q=0.5'
  end

  # Log specified headers for the request
  def request_log request
    return unless log

    log.info("#{request.class}: #{request.path}")

    request.each_header do |k, v|
      log.debug("request-header: #{k} => #{v}")
    end
  end

  def request_add_headers request, headers = {}
    @request_headers.each do |k,v|
      request[k] = v
    end

    headers.each do |field, value|
      case field
      when :etag              then request["ETag"] = value
      when :if_modified_since then request["If-Modified-Since"] = value
      when Symbol then
        raise ArgumentError, "unknown header symbol #{field}"
      else
        request[field] = value
      end
    end
  end

  def request_referer request, uri, referer
    return unless referer
    return if 'https' == referer.scheme.downcase and
              'https' != uri.scheme.downcase

    request['Referer'] = referer
  end

  def request_user_agent request
    request['User-Agent'] = @user_agent if @user_agent
  end

  def resolve(uri, referer = current_page)
    uri = uri.dup if uri.is_a?(URI)

    unless uri.is_a?(URI)
      uri = uri.to_s.strip.gsub(/[^#{0.chr}-#{126.chr}]/o) { |match|
        if RUBY_VERSION >= "1.9.0"
          Mechanize::Util.uri_escape(match)
        else
          sprintf('%%%X', match.unpack($KCODE == 'UTF8' ? 'U' : 'C')[0])
        end
      }

      unescaped = uri.split(/(?:%[0-9A-Fa-f]{2})+|#/)
      escaped   = uri.scan(/(?:%[0-9A-Fa-f]{2})+|#/)

      escaped_uri = Mechanize::Util.html_unescape(
        unescaped.zip(escaped).map { |x,y|
          "#{WEBrick::HTTPUtils.escape(x)}#{y}"
        }.join('')
      )

      begin
        uri = URI.parse(escaped_uri)
      rescue
        uri = URI.parse(WEBrick::HTTPUtils.escape(escaped_uri))
      end
    end

    scheme = uri.relative? ? 'relative' : uri.scheme.downcase
    uri = @scheme_handlers[scheme].call(uri, referer)

    if referer && referer.uri
      if uri.path.length == 0 && uri.relative?
        uri.path = referer.uri.path
      end
    end

    uri.path = '/' if uri.path.length == 0

    if uri.relative?
      raise ArgumentError, "absolute URL needed (not #{uri})" unless
        referer && referer.uri

      base = nil
      if referer.respond_to?(:bases) && referer.parser
        base = referer.bases.last
      end

      uri = ((base && base.uri && base.uri.absolute?) ?
             base.uri :
             referer.uri) + uri
      uri = referer.uri + uri
      # Strip initial "/.." bits from the path
      uri.path.sub!(/^(\/\.\.)+(?=\/)/, '')
    end

    unless ['http', 'https', 'file'].include?(uri.scheme.downcase)
      raise ArgumentError, "unsupported scheme: #{uri.scheme}"
    end

    uri
  end

  def resolve_parameters uri, method, parameters
    case method
    when :head, :get, :delete, :trace then
      if parameters and parameters.length > 0
        uri.query ||= ''
        uri.query << '&' if uri.query.length > 0
        uri.query << Mechanize::Util.build_query_string(parameters)
      end

      return uri, nil
    end

    return uri, parameters
  end

  def response_content_encoding response, body_io
    length = response.content_length || body_io.length

    case response['Content-Encoding']
    when nil, 'none', '7bit' then
      body_io.string
    when 'deflate' then
      log.debug('deflate body') if log

      return if length.zero?

      begin
        Zlib::Inflate.inflate body_io.string
      rescue Zlib::BufError, Zlib::DataError
        log.error('Unable to inflate page, retrying with raw deflate') if log
        begin
          Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(body_io.string)
        rescue Zlib::BufError, Zlib::DataError
          log.error("unable to inflate page: #{$!}") if log
          ''
        end
      end
    when 'gzip', 'x-gzip', 'agzip' then
      log.debug('gzip body') if log

      return if length.zero?

      begin
        zio = Zlib::GzipReader.new body_io
        zio.read
      rescue Zlib::BufError, Zlib::GzipFile::Error
        log.error('Unable to gunzip body, trying raw inflate') if log
        body_io.rewind
        body_io.read 10
        Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(body_io.read)
      rescue Zlib::DataError
        log.error("unable to gunzip page: #{$!}") if log
        ''
      ensure
        zio.close if zio and not zio.closed?
      end
    else
      raise Mechanize::Error,
            "Unsupported Content-Encoding: #{response['Content-Encoding']}"
    end
  end

  def response_cookies response, uri, page
    if Mechanize::Page === page and page.body =~ /Set-Cookie/n
      page.search('//head/meta[@http-equiv="Set-Cookie"]').each do |meta|
        Mechanize::Cookie.parse(uri, meta['content']) { |c|
          log.debug("saved cookie: #{c}") if log
          @cookie_jar.add(uri, c)
        }
      end
    end

    header_cookies = response.get_fields 'Set-Cookie'

    return unless header_cookies

    header_cookies.each do |cookie|
      Mechanize::Cookie.parse(uri, cookie) { |c|
        log.debug("saved cookie: #{c}") if log
        @cookie_jar.add(uri, c)
      }
    end
  end

  def response_follow_meta_refresh response, uri, page, redirects
    return unless @follow_meta_refresh

    redirect_uri = nil
    referer      = page

    if page.respond_to?(:meta_refresh) and (redirect = page.meta_refresh.first)
      redirect_uri = Mechanize::Util.uri_unescape redirect.uri.to_s
      sleep redirect.node['delay'].to_f
      referer = Mechanize::Page.new(nil, {'content-type'=>'text/html'})
    elsif refresh = response['refresh']
      delay, redirect_uri = Mechanize::Page::MetaRefresh.parse refresh, uri
      raise Mechanize::Error, 'Invalid refresh http header' unless delay
      raise Mechanize::RedirectLimitReachedError.new(page, redirects) if
        redirects + 1 > @redirection_limit
      sleep delay.to_f
    end

    if redirect_uri
      @history.push(page, page.uri)
      fetch redirect_uri, :get, {}, [], referer, redirects + 1
    end
  end

  def response_log response
    return unless log

    log.info("status: #{response.class} #{response.http_version} " \
             "#{response.code} #{response.message}")

    response.each_header do |k, v|
      log.debug("response-header: #{k} => #{v}")
    end
  end

  def response_parse response, body, uri
    @context.parse uri, response, body
  end

  def response_read response, request
    body_io = StringIO.new
    body_io.set_encoding Encoding::BINARY if body_io.respond_to? :set_encoding
    total = 0

    begin
      response.read_body { |part|
        total += part.length
        body_io.write(part)
        log.debug("Read #{part.length} bytes (#{total} total)") if log
      }
    rescue Net::HTTP::Persistent::Error => e
      body_io.rewind
      raise Mechanize::ResponseReadError.new(e, response, body_io)
    end

    body_io.rewind

    raise Mechanize::ResponseCodeError, response if
      Net::HTTPUnknownResponse === response

    content_length = response.content_length

    unless Net::HTTP::Head === request or Net::HTTPRedirection === response then
      raise EOFError, "Content-Length (#{content_length}) does not match " \
                      "response body length (#{body_io.length})" if
        content_length and content_length != body_io.length
    end

    body_io
  end

  def response_redirect response, method, page, redirects
    case @redirect_ok
    when true, :all
      # shortcut
    when false, nil
      return page
    when :permanent
      return page if response_class != Net::HTTPMovedPermanently
    end

    log.info("follow redirect to: #{response['Location']}") if log

    from_uri = page.uri

    raise Mechanize::RedirectLimitReachedError.new(page, redirects) if
      redirects + 1 > @redirection_limit

    redirect_method = method == :head ? :head : :get

    page = fetch(response['Location'].to_s, redirect_method, {}, [], page,
                 redirects + 1)

    @history.push(page, from_uri)

    return page
  end

  def response_authenticate(response, page, uri, request, headers, params,
                            referer)
    raise Mechanize::ResponseCodeError, page unless @user || @password
    raise Mechanize::ResponseCodeError, page if @auth_hash.has_key?(uri.host)

    if response['www-authenticate'] =~ /Digest/i
      @auth_hash[uri.host] = :digest
      if response['server'] =~ /Microsoft-IIS/
        @auth_hash[uri.host] = :iis_digest
      end
      @digest = response['www-authenticate']
    else
      @auth_hash[uri.host] = :basic
    end

    fetch uri, request.method.downcase.to_sym, headers, params, referer
  end

  def robots= value
    require 'webrobots' if value
    @webrobots = nil if value != @robots
    @robots = value
  end

  ##
  # Tests if this agent is allowed to access +url+, consulting the site's
  # robots.txt.

  def robots_allowed? uri
    return true if uri.request_uri == '/robots.txt'

    webrobots.allowed? uri
  end

  # Opposite of robots_allowed?

  def robots_disallowed? url
    !robots_allowed? url
  end

  # Returns an error object if there is an error in fetching or parsing
  # robots.txt of the site +url+.
  def robots_error(url)
    webrobots.error(url)
  end

  # Raises the error if there is an error in fetching or parsing robots.txt of
  # the site +url+.
  def robots_error!(url)
    webrobots.error!(url)
  end

  # Removes robots.txt cache for the site +url+.
  def robots_reset(url)
    webrobots.reset(url)
  end

  def set_http
    @http = Net::HTTP::Persistent.new 'mechanize', @proxy_uri

    @http.keep_alive = @keep_alive_time

    @http.ca_file         = @ca_file
    @http.verify_callback = @verify_callback

    if @cert and @key then
      cert = if OpenSSL::X509::Certificate === @cert then
               @cert
             else
               OpenSSL::X509::Certificate.new ::File.read @cert
             end

      key = if OpenSSL::PKey::PKey === @key then
              @key
            else
              OpenSSL::PKey::RSA.new ::File.read(@key), @pass
            end

      @http.certificate = cert
      @http.private_key = key
    end
  end

  # Sets the proxy address, port, user, and password +addr+ should be a host,
  # with no "http://"
  def set_proxy(addr, port, user = nil, pass = nil)
    return unless addr and port
    @proxy_uri = URI "http://#{addr}"
    @proxy_uri.port = port
    @proxy_uri.user     = user if user
    @proxy_uri.password = pass if pass

    @proxy_uri
  end

  def user_agent= user_agent
    @webrobots = nil if user_agent != @user_agent
    @user_agent = user_agent
  end

  # Returns a visited page for the url passed in, otherwise nil
  def visited_page url
    @history.visited_page resolve url
  end

  def get_robots(uri) # :nodoc:
    fetch(uri).body
  rescue Mechanize::ResponseCodeError => e
    return '' if e.response_code == '404'
    raise e
  end

  def webrobots
    @webrobots ||= WebRobots.new(@user_agent, :http_get => method(:get_robots))
  end

end

