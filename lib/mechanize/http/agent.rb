require 'tempfile'
require 'net/ntlm'
require 'kconv'

##
# An HTTP (and local disk access) user agent

class Mechanize::HTTP::Agent

  # :section: Headers

  # Disables If-Modified-Since conditional requests (enabled by default)
  attr_accessor :conditional_requests

  # Is gzip compression of requests enabled?
  attr_accessor :gzip_enabled

  # A hash of request headers to be used for every request
  attr_accessor :request_headers

  # The User-Agent header to send
  attr_reader :user_agent

  # :section: History

  # history of requests made
  attr_accessor :history

  # :section: Hooks

  # A list of hooks to call after retrieving a response.  Hooks are called with
  # the agent and the response returned.
  attr_reader :post_connect_hooks

  # A list of hooks to call before making a request.  Hooks are called with
  # the agent and the request to be performed.
  attr_reader :pre_connect_hooks

  # A list of hooks to call to handle the content-encoding of a request.
  attr_reader :content_encoding_hooks

  # :section: HTTP Authentication

  attr_reader :authenticate_methods # :nodoc:
  attr_reader :digest_challenges # :nodoc:
  attr_accessor :user
  attr_accessor :password

  # :section: Redirection

  # Follow HTML meta refresh and HTTP Refresh.  If set to +:anywhere+ meta
  # refresh tags outside of the head element will be followed.
  attr_accessor :follow_meta_refresh

  # Follow an HTML meta refresh that has no "url=" in the content attribute.
  #
  # Defaults to false to prevent infinite refresh loops.
  attr_accessor :follow_meta_refresh_self

  # Controls how this agent deals with redirects.  The following values are
  # allowed:
  #
  # :all, true:: All 3xx redirects are followed (default)
  # :permanent:: Only 301 Moved Permanantly redirects are followed
  # false:: No redirects are followed
  attr_accessor :redirect_ok

  # Maximum number of redirects to follow
  attr_accessor :redirection_limit

  # :section: Robots

  # When true, this agent will consult the site's robots.txt for each access.
  attr_reader :robots

  # :section: SSL

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

  # :section: Timeouts

  # Reset connections that have not been used in this many seconds
  attr_reader   :idle_timeout

  # Set to false to disable HTTP/1.1 keep-alive requests
  attr_accessor :keep_alive

  # Length of time to wait until a connection is opened in seconds
  attr_accessor :open_timeout

  # Length of time to attempt to read data from the server
  attr_accessor  :read_timeout

  # :section:

  # The cookies for this agent
  attr_accessor :cookie_jar

  # URI for a proxy connection
  attr_reader :proxy_uri

  # Retry non-idempotent requests?
  attr_reader :retry_change_requests

  # Responses larger than this will be written to a Tempfile instead of stored
  # in memory.
  attr_accessor :max_file_buffer

  # :section: Utility

  # The context parses responses into pages
  attr_accessor :context

  attr_reader :http # :nodoc:

  # Handlers for various URI schemes
  attr_accessor :scheme_handlers

  # :section:

  # Creates a new Mechanize HTTP user agent.  The user agent is an
  # implementation detail of mechanize and its API may change at any time.

  def initialize
    @conditional_requests     = true
    @context                  = nil
    @content_encoding_hooks   = []
    @cookie_jar               = Mechanize::CookieJar.new
    @follow_meta_refresh      = false
    @follow_meta_refresh_self = false
    @gzip_enabled             = true
    @history                  = Mechanize::History.new
    @idle_timeout             = nil
    @keep_alive               = true
    @keep_alive_time          = 300
    @max_file_buffer          = 10240
    @open_timeout             = nil
    @post_connect_hooks       = []
    @pre_connect_hooks        = []
    @proxy_uri                = nil
    @read_timeout             = nil
    @redirect_ok              = true
    @redirection_limit        = 20
    @request_headers          = {}
    @retry_change_requests    = false
    @robots                   = false
    @user_agent               = nil
    @webrobots                = nil

    # HTTP Authentication
    @authenticate_parser  = Mechanize::HTTP::WWWAuthenticateParser.new
    @authenticate_methods = Hash.new do |methods, uri|
      methods[uri] = Hash.new do |realms, auth_scheme|
        realms[auth_scheme] = []
      end
    end
    @digest_auth          = Net::HTTP::DigestAuth.new
    @digest_challenges    = {}
    @password             = nil # HTTP auth password
    @user                 = nil # HTTP auth user

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

  # Retrieves +uri+ and parses it into a page or other object according to
  # PluggableParser.  If the URI is an HTTP or HTTPS scheme URI the given HTTP
  # +method+ is used to retrieve it, along with the HTTP +headers+, request
  # +params+ and HTTP +referer+.
  #
  # +redirects+ tracks the number of redirects experienced when retrieving the
  # page.  If it is over the redirection_limit an error will be raised.

  def fetch uri, method = :get, headers = {}, params = [],
            referer = current_page, redirects = 0
    referer_uri = referer ? referer.uri : nil

    uri = resolve uri, referer

    uri, params = resolve_parameters uri, method, params

    request = http_request uri, method, params

    connection = connection_for uri

    request_auth             request, uri

    disable_keep_alive       request
    enable_gzip              request

    request_language_charset request
    request_cookies          request, uri
    request_host             request, uri
    request_referer          request, uri, referer_uri
    request_user_agent       request
    request_add_headers      request, headers

    pre_connect              request

    # Consult robots.txt
    if robots && uri.is_a?(URI::HTTP)
      robots_allowed?(uri) or raise Mechanize::RobotsDisallowedError.new(uri)
    end

    # Add If-Modified-Since if page is in history
    page = visited_page(uri)

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

    hook_content_encoding response, uri, response_body_io

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
      response_redirect response, method, page, redirects, referer
    when Net::HTTPUnauthorized
      response_authenticate(response, page, uri, request, headers, params,
                            referer)
    else
      raise Mechanize::ResponseCodeError.new(page), "Unhandled response"
    end
  end

  # Retry non-idempotent requests

  def retry_change_requests= retri
    @retry_change_requests = retri
    @http.retry_change_requests = retri if @http
  end

  # :section: Headers

  def user_agent= user_agent
    @webrobots = nil if user_agent != @user_agent
    @user_agent = user_agent
  end

  # :section: History

  # Equivalent to the browser back button.  Returns the most recent page
  # visited.
  def back
    @history.pop
  end

  ##
  # Returns the latest page loaded by the agent

  def current_page
    @history.last
  end

  def max_history
    @history.max_size
  end

  def max_history=(length)
    @history.max_size = length
  end

  # Returns a visited page for the url passed in, otherwise nil
  def visited_page url
    @history.visited_page resolve url
  end

  # :section: Hooks

  def hook_content_encoding response, uri, response_body_io
    @content_encoding_hooks.each do |hook|
      hook.call self, uri, response, response_body_io
    end
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

  # :section: Request

  def connection_for uri
    case uri.scheme.downcase
    when 'http', 'https' then
      return @http
    when 'file' then
      return Mechanize::FileConnection.new
    end
  end

  def disable_keep_alive request
    request['connection'] = 'close' unless @keep_alive
  end

  def enable_gzip request
    request['accept-encoding'] = if @gzip_enabled
                                   'gzip,deflate,identity'
                                 else
                                   'identity'
                                 end
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

  def request_auth request, uri
    base_uri = uri + '/'
    schemes = @authenticate_methods[base_uri]

    if realm = schemes[:digest].find { |r| r.uri == base_uri } then
      request_auth_digest request, uri, realm, base_uri, false
    elsif realm = schemes[:iis_digest].find { |r| r.uri == base_uri } then
      request_auth_digest request, uri, realm, base_uri, true
    elsif schemes[:basic].find { |r| r.uri == base_uri } then
      request.basic_auth @user, @password
    end
  end

  def request_auth_digest request, uri, realm, base_uri, iis
    challenge = @digest_challenges[realm]

    uri.user = @user
    uri.password = @password

    auth = @digest_auth.auth_header uri, challenge.to_s, request.method, iis
    request['Authorization'] = auth
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

  # :section: Response

  def get_meta_refresh response, uri, page
    return nil unless @follow_meta_refresh

    if page.respond_to?(:meta_refresh) and
       (redirect = page.meta_refresh.first) then
      [redirect.delay, redirect.href] unless
        not @follow_meta_refresh_self and redirect.link_self
    elsif refresh = response['refresh']
      delay, href, link_self = Mechanize::Page::MetaRefresh.parse refresh, uri
      raise Mechanize::Error, 'Invalid refresh http header' unless delay
      [delay.to_f, href] unless
        not @follow_meta_refresh_self and link_self
    end
  end

  def response_authenticate(response, page, uri, request, headers, params,
                            referer)
    raise Mechanize::UnauthorizedError, page unless @user || @password

    challenges = @authenticate_parser.parse response['www-authenticate']

    if challenge = challenges.find { |c| c.scheme =~ /^Digest$/i } then
      realm = challenge.realm uri

      auth_scheme = if response['server'] =~ /Microsoft-IIS/ then
                      :iis_digest
                    else
                      :digest
                    end

      existing_realms = @authenticate_methods[realm.uri][auth_scheme]

      raise Mechanize::UnauthorizedError, page if
        existing_realms.include? realm

      existing_realms << realm
      @digest_challenges[realm] = challenge
    elsif challenge = challenges.find { |c| c.scheme == 'NTLM' } then
      existing_realms = @authenticate_methods[uri + '/'][:ntlm]

      raise Mechanize::UnauthorizedError, page if
        existing_realms.include?(realm) and not challenge.params

      existing_realms << realm

      if challenge.params then
        type_2 = Net::NTLM::Message.decode64 challenge.params

        type_3 = type_2.response({ :user => @user, :password => @password, },
                                 { :ntlmv2 => true }).encode64

        headers['Authorization'] = "NTLM #{type_3}"
      else
        type_1 = Net::NTLM::Message::Type1.new.encode64
        headers['Authorization'] = "NTLM #{type_1}"
      end
    elsif challenge = challenges.find { |c| c.scheme == 'Basic' } then
      realm = challenge.realm uri

      existing_realms = @authenticate_methods[realm.uri][:basic]

      raise Mechanize::UnauthorizedError, page if
        existing_realms.include? realm

      existing_realms << realm
    else
      raise Mechanize::UnauthorizedError, page
    end

    fetch uri, request.method.downcase.to_sym, headers, params, referer
  end

  def response_content_encoding response, body_io
    length = response.content_length

    length = case body_io
             when IO, Tempfile then
               body_io.stat.size
             else
               body_io.length
             end unless length

    out_io = nil

    case response['Content-Encoding']
    when nil, 'none', '7bit' then
      out_io = body_io
    when 'deflate' then
      log.debug('deflate body') if log

      return if length.zero?

      begin
        out_io = inflate body_io
      rescue Zlib::BufError, Zlib::DataError
        log.error('Unable to inflate page, retrying with raw deflate') if log
        body_io.rewind
        begin
          out_io = inflate body_io, -Zlib::MAX_WBITS
        rescue Zlib::BufError, Zlib::DataError
          log.error("unable to inflate page: #{$!}") if log
          nil
        end
      end
    when 'gzip', 'x-gzip' then
      log.debug('gzip body') if log

      return if length.zero?

      begin
        zio = Zlib::GzipReader.new body_io
        out_io = Tempfile.new 'mechanize-decode'

        until zio.eof? do
          out_io.write zio.read 16384
        end
      rescue Zlib::BufError, Zlib::GzipFile::Error
        log.error('Unable to gunzip body, trying raw inflate') if log
        body_io.rewind
        body_io.read 10

        out_io = inflate body_io, -Zlib::MAX_WBITS
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

    out_io.flush
    out_io.rewind

    out_io
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
    delay, new_url = get_meta_refresh(response, uri, page)
    return nil unless new_url

    raise Mechanize::RedirectLimitReachedError.new(page, redirects) if
      redirects + 1 > @redirection_limit

    sleep delay
    @history.push(page, page.uri)
    fetch new_url, :get, {}, [],
          Mechanize::Page.new(nil, {'content-type'=>'text/html'}), redirects
  end

  def response_log response
    return unless log

    log.info("status: #{response.class} #{response.http_version} " \
             "#{response.code} #{response.message}")

    response.each_header do |k, v|
      log.debug("response-header: #{k} => #{v}")
    end
  end

  def response_parse response, body_io, uri
    @context.parse uri, response, body_io
  end

  def response_read response, request
    content_length = response.content_length

    if content_length and content_length > @max_file_buffer then
      body_io = Tempfile.new 'mechanize-raw'
      body_io.binmode if defined? body_io.binmode
    else
      body_io = StringIO.new
    end

    body_io.set_encoding Encoding::BINARY if body_io.respond_to? :set_encoding
    total = 0

    begin
      response.read_body { |part|
        total += part.length

        if StringIO === body_io and total > @max_file_buffer then
          new_io = Tempfile.new 'mechanize-raw'
          new_io.binmode if defined? binmode

          new_io.write body_io.string

          body_io = new_io
        end

        body_io.write(part)
        log.debug("Read #{part.length} bytes (#{total} total)") if log
      }
    rescue Net::HTTP::Persistent::Error => e
      body_io.rewind
      raise Mechanize::ResponseReadError.new(e, response, body_io)
    end

    body_io.flush
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

  def response_redirect response, method, page, redirects, referer = current_page
    case @redirect_ok
    when true, :all
      # shortcut
    when false, nil
      return page
    when :permanent
      return page unless Net::HTTPMovedPermanently === response
    end

    log.info("follow redirect to: #{response['Location']}") if log

    raise Mechanize::RedirectLimitReachedError.new(page, redirects) if
      redirects + 1 > @redirection_limit

    redirect_method = method == :head ? :head : :get

    from_uri = page.uri
    @history.push(page, from_uri)
    new_uri = from_uri + response['Location'].to_s

    fetch new_uri, redirect_method, {}, [], referer, redirects + 1
  end

  # :section: Robots

  def get_robots(uri) # :nodoc:
    fetch(uri).body
  rescue Mechanize::ResponseCodeError => e
    return '' if e.response_code == '404'
    raise e
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

  def webrobots
    @webrobots ||= WebRobots.new(@user_agent, :http_get => method(:get_robots))
  end

  # :section: SSL

  def certificate
    @http.certificate
  end

  # :section: Timeouts

  # Sets the conection idle timeout for persistent connections
  def idle_timeout= timeout
    @idle_timeout = timeout
    @http.idle_timeout = timeout if @http
  end

  # :section: Utility

  def inflate compressed, window_bits = nil
    inflate = Zlib::Inflate.new window_bits
    out_io = Tempfile.new 'mechanize-decode'

    until compressed.eof? do
      out_io.write inflate.inflate compressed.read 1024
    end

    out_io.write inflate.finish

    out_io
  end

  def log
    Mechanize.log
  end

  def set_http
    @http = Net::HTTP::Persistent.new 'mechanize', @proxy_uri

    @http.keep_alive = @keep_alive_time
    @http.idle_timeout = @idle_timeout if @idle_timeout
    @http.retry_change_requests = @retry_change_requests

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

end

