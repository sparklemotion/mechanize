require 'openssl'
require 'net/http/persistent'
require 'uri'
require 'webrick/httputils'
require 'zlib'
require 'stringio'
require 'digest/md5'
require 'fileutils'
require 'nokogiri'
require 'forwardable'

require 'iconv' if RUBY_VERSION < '1.9.2'

require 'nkf'
require 'mutex_m'

require 'mechanize/util'
require 'mechanize/content_type_error'
require 'mechanize/response_code_error'
require 'mechanize/unsupported_scheme_error'
require 'mechanize/redirect_limit_reached_error'
require 'mechanize/redirect_not_get_or_head_error'
require 'mechanize/cookie'
require 'mechanize/cookie_jar'
require 'mechanize/history'
require 'mechanize/form'
require 'mechanize/pluggable_parsers'
require 'mechanize/file_response'
require 'mechanize/inspect'
require 'mechanize/chain'
require 'mechanize/monkey_patch'
require 'mechanize/uri_resolver'

# = Synopsis
# The Mechanize library is used for automating interaction with a website.  It
# can follow links, and submit forms.  Form fields can be populated and
# submitted.  A history of URL's is maintained and can be queried.
#
# == Example
#  require 'rubygems'
#  require 'mechanize'
#  require 'logger'
#
#  agent = Mechanize.new { |a| a.log = Logger.new("mech.log") }
#  agent.user_agent_alias = 'Mac Safari'
#  page = agent.get("http://www.google.com/")
#  search_form = page.form_with(:name => "f")
#  search_form.field_with(:name => "q").value = "Hello"
#  search_results = agent.submit(search_form)
#  puts search_results.body
class Mechanize
  ##
  # The version of Mechanize you are using.
  VERSION = '1.0.1.beta'

  ##
  # User Agent aliases
  AGENT_ALIASES = {
    'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
    'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10',
    'Mac FireFox' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6',
    'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Linux Firefox' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.1) Gecko/20100122 firefox/3.6.1',
    'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
    'iPhone' => 'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3',
    'Mechanize' => "WWW-Mechanize/#{VERSION} (http://rubyforge.org/projects/mechanize/)"
  }

  attr_accessor :cookie_jar
  attr_accessor :open_timeout, :read_timeout
  attr_accessor :user_agent
  attr_accessor :watch_for_set
  attr_accessor :ca_file
  attr_accessor :key
  attr_accessor :cert
  attr_accessor :pass

  # Controls how this agent deals with redirects.  If it is set to
  # true or :all, all 3xx redirects are automatically followed.  This
  # is the default behavior.  If it is :permanent, only 301 (Moved
  # Permanently) redirects are followed.  If it is a false value, no
  # redirects are followed.
  attr_accessor :redirect_ok

  attr_accessor :gzip_enabled
  attr_accessor :keep_alive_time
  attr_accessor :keep_alive
  attr_accessor :conditional_requests
  attr_accessor :follow_meta_refresh
  attr_accessor :verify_callback
  attr_accessor :history_added
  attr_accessor :scheme_handlers
  attr_accessor :redirection_limit

  # A hash of custom request headers
  attr_accessor :request_headers

  # Proxy settings
  attr_reader :proxy_addr
  attr_reader :proxy_pass
  attr_reader :proxy_port
  attr_reader :proxy_user

  # The HTML parser to be used when parsing documents
  attr_accessor :html_parser

  attr_reader :http # :nodoc:

  attr_reader :history
  attr_reader :pluggable_parser

  alias :follow_redirect? :redirect_ok

  @html_parser = Nokogiri::HTML
  class << self
    attr_accessor :html_parser, :log

    def inherited(child)
      child.html_parser ||= html_parser
      child.log ||= log
      super
    end
  end

  def initialize
    # attr_accessors
    @cookie_jar     = CookieJar.new
    @log            = nil
    @open_timeout   = nil
    @read_timeout   = nil
    @user_agent     = AGENT_ALIASES['Mechanize']
    @watch_for_set  = nil
    @history_added  = nil
    @ca_file        = nil # OpenSSL server certificate file

    # callback for OpenSSL errors while verifying the server certificate
    # chain, can be used for debugging or to ignore errors by always
    # returning _true_
    @verify_callback = nil
    @cert           = nil # OpenSSL Certificate
    @key            = nil # OpenSSL Private Key
    @pass           = nil # OpenSSL Password
    @redirect_ok    = true
    @gzip_enabled   = true

    # attr_readers
    @history        = Mechanize::History.new
    @pluggable_parser = PluggableParser.new

    # Auth variables
    @user           = nil # Auth User
    @password       = nil # Auth Password
    @digest         = nil # DigestAuth Digest
    @auth_hash      = {}  # Keep track of urls for sending auth
    @request_headers= {}  # A hash of request headers to be used

    @conditional_requests = true

    @follow_meta_refresh  = false
    @redirection_limit    = 20

    # Connection Cache & Keep alive
    @keep_alive_time  = 300
    @keep_alive       = true

    @resolver = Mechanize::URIResolver.new
    @scheme_handlers = @resolver.scheme_handlers

    @pre_connect_hook = Chain::PreConnectHook.new
    @post_connect_hook = Chain::PostConnectHook.new

    set_http
    @html_parser = self.class.html_parser

    yield self if block_given?
  end

  def max_history=(length); @history.max_size = length end
  def max_history; @history.max_size end
  def log=(l); self.class.log = l end
  def log; self.class.log end

  def pre_connect_hooks
    @pre_connect_hook.hooks
  end

  def post_connect_hooks
    @post_connect_hook.hooks
  end

  # Sets the proxy address, port, user, and password
  # +addr+ should be a host, with no "http://"
  def set_proxy(addr, port, user = nil, pass = nil)
    proxy = URI.parse "http://#{addr}"
    proxy.port = port
    proxy.user     = user if user
    proxy.password = pass if pass

    set_http proxy

    nil
  end

  # Set the user agent for the Mechanize object.
  # See AGENT_ALIASES
  def user_agent_alias=(al)
    self.user_agent = AGENT_ALIASES[al] || raise("unknown agent alias")
  end

  # Returns a list of cookies stored in the cookie jar.
  def cookies
    @cookie_jar.to_a
  end

  # Sets the user and password to be used for authentication.
  def auth(user, password)
    @user       = user
    @password   = password
  end
  alias :basic_auth :auth

  # Fetches the URL passed in and returns a page.
  def get(options, parameters = [], referer = nil)
    verb = :get

    unless options.is_a? Hash
      url = options
      unless parameters.respond_to?(:each) # FIXME: Remove this in 0.8.0
        referer = parameters
        parameters = []
      end
    else
      raise ArgumentError.new("url must be specified") unless url = options[:url]
      parameters = options[:params] || []
      referer    = options[:referer]
      headers    = options[:headers]
      verb       = options[:verb] || verb
    end

    unless referer
      if url.to_s =~ %r{\Ahttps?://}
        referer = Page.new(nil, {'content-type'=>'text/html'})
      else
        referer = current_page || Page.new(nil, {'content-type'=>'text/html'})
      end
    end

    # FIXME: Huge hack so that using a URI as a referer works.  I need to
    # refactor everything to pass around URIs but still support
    # Mechanize::Page#base
    unless referer.is_a?(Mechanize::File)
      referer = referer.is_a?(String) ?
      Page.new(URI.parse(referer), {'content-type' => 'text/html'}) :
        Page.new(referer, {'content-type' => 'text/html'})
    end

    # fetch the page
    page = fetch_page(  :uri      => url,
                        :referer  => referer,
                        :headers  => headers || {},
                        :verb     => verb,
                        :params   => parameters
                        )
    add_to_history(page)
    yield page if block_given?
    page
  end

  ####
  # PUT to +url+ with +entity+, and setting +options+:
  #
  #   put('http://tenderlovemaking.com/', 'new content', :headers => {'Content-Type' => 'text/plain'})
  #
  def put(url, entity, options = {})
    request_with_entity(:put, url, entity, options)
  end

  ####
  # DELETE to +url+ with +query_params+, and setting +options+:
  #
  #   delete('http://tenderlovemaking.com/', {'q' => 'foo'}, :headers => {})
  #
  def delete(url, query_params = {}, options = {})
    page = head(url, query_params, options.merge({:verb => :delete}))
    add_to_history(page)
    page
  end

  ####
  # HEAD to +url+ with +query_params+, and setting +options+:
  #
  #   head('http://tenderlovemaking.com/', {'q' => 'foo'}, :headers => {})
  #
  def head(url, query_params = {}, options = {})
    options = {
      :uri      => url,
      :headers  => {},
      :params   => query_params,
      :verb     => :head
    }.merge(options)
    # fetch the page
    page = fetch_page(options)
    yield page if block_given?
    page
  end

  # Fetch a file and return the contents of the file.
  def get_file(url)
    get(url).body
  end

  # If the parameter is a string, finds the button or link with the
  # value of the string and clicks it. Otherwise, clicks the
  # Mechanize::Page::Link object passed in. Returns the page fetched.
  def click(link)
    case link
    when String, Regexp
      if real_link = page.link_with(:text => link)
        click real_link
      else
        button = nil
        form = page.forms.find do |f|
          button = f.button_with(:value => link)
          button.is_a? Form::Submit
        end
        submit form, button if form
      end
    else
      referer = link.page rescue referer = nil
      href = link.respond_to?(:href) ? link.href :
        (link['href'] || link['src'])
      get(:url => href, :referer => (referer || current_page()))
    end
  end

  # Equivalent to the browser back button.  Returns the most recent page
  # visited.
  def back
    @history.pop
  end

  # Posts to the given URL with the request entity.  The request
  # entity is specified by either a string, or a list of key-value
  # pairs represented by a hash or an array of arrays.
  #
  # Examples:
  #  agent.post('http://example.com/', "foo" => "bar")
  #
  #  agent.post('http://example.com/', [ ["foo", "bar"] ])
  #
  #  agent.post('http://example.com/', "<message>hello</message>", 'Content-Type' => 'application/xml')
  def post(url, query={}, headers={})
    if query.is_a?(String)
      return request_with_entity(:post, url, query, :headers => headers)
    end
    node = {}
    # Create a fake form
    class << node
      def search(*args); []; end
    end
    node['method'] = 'POST'
    node['enctype'] = 'application/x-www-form-urlencoded'

    form = Form.new(node)
    query.each { |k,v|
      if v.is_a?(IO)
        form.enctype = 'multipart/form-data'
        ul = Form::FileUpload.new({'name' => k.to_s},::File.basename(v.path))
        ul.file_data = v.read
        form.file_uploads << ul
      else
        form.fields << Form::Field.new({'name' => k.to_s},v)
      end
    }
    post_form(url, form, headers)
  end

  # Submit a form with an optional button.
  # Without a button:
  #  page = agent.get('http://example.com')
  #  agent.submit(page.forms.first)
  # With a button
  #  agent.submit(page.forms.first, page.forms.first.buttons.first)
  def submit(form, button=nil, headers={})
    form.add_button_to_query(button) if button
    case form.method.upcase
    when 'POST'
      post_form(form.action, form, headers)
    when 'GET'
      get(  :url      => form.action.gsub(/\?[^\?]*$/, ''),
            :params   => form.build_query,
            :headers  => headers,
            :referer  => form.page
            )
    else
      raise "unsupported method: #{form.method.upcase}"
    end
  end

  def request_with_entity(verb, url, entity, options={})
    cur_page = current_page || Page.new( nil, {'content-type'=>'text/html'})

    options = {
      :uri      => url,
      :referer  => cur_page,
      :headers  => {},
    }.update(options)

    headers = {
      'Content-Type' => 'application/octet-stream',
      'Content-Length' => entity.size.to_s,
    }.update(options[:headers])

    options.update({
                     :verb => verb,
                     :params => [entity],
                     :headers => headers,
                   })

    page = fetch_page(options)
    add_to_history(page)
    page
  end

  # Returns the current page loaded by Mechanize
  def current_page
    @history.last
  end

  # Returns whether or not a url has been visited
  def visited?(url)
    ! visited_page(url).nil?
  end

  # Returns a visited page for the url passed in, otherwise nil
  def visited_page(url)
    if url.respond_to? :href
      url = url.href
    end
    @history.visited_page(resolve(url))
  end

  # Runs given block, then resets the page history as it was before. self is
  # given as a parameter to the block. Returns the value of the block.
  def transact
    history_backup = @history.dup
    begin
      yield self
    ensure
      @history = history_backup
    end
  end

  alias :page :current_page

  private

  def resolve(url, referer = current_page())
    hash = { :uri => url, :referer => referer }
    Chain.new([
                       Chain::URIResolver.new(@resolver)
                      ]).handle(hash)
    hash[:uri].to_s
  end

  def set_http proxy = nil
    @http = Net::HTTP::Persistent.new 'mechanize', proxy

    @http.keep_alive = @keep_alive_time

    @http.ca_file         = @ca_file
    @http.verify_callback = @verify_callback

    if @cert and @key then
      @http.certificate = OpenSSL::X509::Certificate.new ::File.read(@cert)
      @http.private_key = OpenSSL::PKey::RSA.new ::File.read(@key), @pass
    end
  end

  def post_form(url, form, headers = {})
    cur_page = form.page || current_page ||
      Page.new( nil, {'content-type'=>'text/html'})

    request_data = form.request_data

    log.debug("query: #{ request_data.inspect }") if log

    # fetch the page
    page = fetch_page(  :uri      => url,
                        :referer  => cur_page,
                        :verb     => :post,
                        :params   => [request_data],
                        :headers  => {
                          'Content-Type'    => form.enctype,
                          'Content-Length'  => request_data.size.to_s,
                        }.merge(headers))
    add_to_history(page)
    page
  end

  # uri is an absolute URI
  def fetch_page(params)
    options = {
      :request    => nil,
      :response   => nil,
      :connection => nil,
      :referer    => current_page(),
      :uri        => nil,
      :verb       => :get,
      :agent      => self,
      :redirects  => 0,
      :params     => [],
      :headers    => {},
    }.merge(params)

    before_connect = Chain.new([
                                Chain::URIResolver.new(@resolver),
                                Chain::ParameterResolver.new,
                                Chain::RequestResolver.new,
                                Chain::ConnectionResolver.new,
                                Chain::AuthHeaders.new(@auth_hash, @user, @password, @digest),
                                Chain::HeaderResolver.new(
                                                          @cookie_jar,
                                                          @user_agent,
                                                          @gzip_enabled,
                                                          @request_headers
                                                          ),
                                Chain::CustomHeaders.new,
                                @pre_connect_hook,
                               ], @http)

    before_connect.handle(options)

    uri           = options[:uri]
    request       = options[:request]
    cur_page      = options[:referer]
    request_data  = options[:params]
    redirects     = options[:redirects]
    http_obj      = options[:connection]

    # Add If-Modified-Since if page is in history
    if( (page = visited_page(uri)) && page.response['Last-Modified'] )
      request['If-Modified-Since'] = page.response['Last-Modified']
    end if(@conditional_requests)

    # Specify timeouts if given
    http_obj.open_timeout = @open_timeout if @open_timeout
    http_obj.read_timeout = @read_timeout if @read_timeout

    # Log specified headers for the request
    log.info("#{ request.class }: #{ request.path }") if log
    request.each_header do |k, v|
      log.debug("request-header: #{ k } => #{ v }")
    end if log

    # Send the request
    response = http_obj.request(uri, request) { |r|
      connection_chain = Chain.new([
                                    Chain::ResponseReader.new(r),
                                    Chain::BodyDecodingHandler.new,
                                   ])
      connection_chain.handle(options)
    }

    after_connect = Chain.new([
                               @post_connect_hook,
                               Chain::ResponseBodyParser.new(@pluggable_parser, @watch_for_set),
                               Chain::ResponseHeaderHandler.new(@cookie_jar),
                              ])
    after_connect.handle(options)

    res_klass = options[:res_klass]
    response_body = options[:response_body]
    page = options[:page]

    log.info("status: #{ page.code }") if log

    if follow_meta_refresh
      redirect_uri  = nil
      referer       = page
      if (page.respond_to?(:meta) && (redirect = page.meta.first))
        redirect_uri = redirect.uri.to_s
        sleep redirect.node['delay'].to_f
        referer = Page.new(nil, {'content-type'=>'text/html'})
      elsif refresh = response['refresh']
        delay, redirect_uri = Page::Meta.parse(refresh, uri)
        raise StandardError, "Invalid refresh http header" unless delay
        if redirects + 1 > redirection_limit
          raise RedirectLimitReachedError.new(page, redirects)
        end
        sleep delay.to_f
      end

      if redirect_uri
        @history.push(page, page.uri)
        return fetch_page(
                          :uri        => redirect_uri,
                          :referer    => referer,
                          :params     => [],
                          :verb       => :get,
                          :redirects  => redirects + 1
                          )
      end
    end

    return page if res_klass <= Net::HTTPSuccess

    if res_klass == Net::HTTPNotModified
      log.debug("Got cached page") if log
      return visited_page(uri) || page
    elsif res_klass <= Net::HTTPRedirection
      case redirect_ok
      when true, :all
        # shortcut
      when false, nil
        return page
      when :permanent
        return page if res_klass != Net::HTTPMovedPermanently
      end
      log.info("follow redirect to: #{ response['Location'] }") if log
      from_uri  = page.uri
      raise RedirectLimitReachedError.new(page, redirects) if redirects + 1 > redirection_limit
      redirect_verb = options[:verb] == :head ? :head : :get
      page = fetch_page(  :uri => response['Location'].to_s,
                          :referer => page,
                          :params  => [],
                          :verb => redirect_verb,
                          :redirects => redirects + 1
                          )
      @history.push(page, from_uri)
      return page
    elsif res_klass <= Net::HTTPUnauthorized
      raise ResponseCodeError.new(page) unless @user || @password
      raise ResponseCodeError.new(page) if @auth_hash.has_key?(uri.host)
      if response['www-authenticate'] =~ /Digest/i
        @auth_hash[uri.host] = :digest
        if response['server'] =~ /Microsoft-IIS/
          @auth_hash[uri.host] = :iis_digest
        end
        @digest = response['www-authenticate']
      else
        @auth_hash[uri.host] = :basic
      end
      return fetch_page(  :uri      => uri,
                          :referer  => cur_page,
                          :verb     => request.method.downcase.to_sym,
                          :params   => request_data,
                          :headers  => options[:headers]
                          )
    end

    raise ResponseCodeError.new(page), "Unhandled response", caller
  end

  def add_to_history(page)
    @history.push(page, resolve(page.uri))
    history_added.call(page) if history_added
  end
end

module WWW
  def self.const_missing klass
    warn <<eomsg
!!!!! DEPRECATION NOTICE !!!!!
The WWW constant is deprecated, please switch to the new top-level Mechanize
constant.  WWW will be removed in Mechanize version 2.0

You've referenced the WWW constant from #{caller.first}, please
switch the "WWW" to "Mechanize".  Thanks!

Sincerely,

  Pew Pew Pew
eomsg
    Object.const_get(klass)
  end
end
