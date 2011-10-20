require 'fileutils'
require 'forwardable'
require 'iconv' if RUBY_VERSION < '1.9.2'
require 'mutex_m'
require 'net/http/digest_auth'
require 'net/http/persistent'
require 'nkf'
require 'nokogiri'
require 'openssl'
require 'stringio'
require 'uri'
require 'webrick/httputils'
require 'zlib'

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
  VERSION = '2.0.2'

  class Error < RuntimeError
  end

  ruby_version = if RUBY_PATCHLEVEL >= 0 then
                   "#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
                 else
                   "#{RUBY_VERSION}dev#{RUBY_REVISION}"
                 end

  # HTTP/1.1 keep-alives are always active.  This does nothing.
  attr_accessor :keep_alive

  # HTTP/1.0 keep-alive time.  This is no longer supported by mechanize as it
  # now uses net-http-persistent which only supports HTTP/1.1 persistent
  # connections
  attr_accessor :keep_alive_time

  ##
  # User Agent aliases

  AGENT_ALIASES = {
    'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
    'Windows IE 8' => 'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
    'Windows IE 9' => 'Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0)',
    'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10',
    'Mac FireFox' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6',
    'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Linux Firefox' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.2.1) Gecko/20100122 firefox/3.6.1',
    'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
    'iPhone' => 'Mozilla/5.0 (iPhone; U; CPU like Mac OS X; en) AppleWebKit/420+ (KHTML, like Gecko) Version/3.0 Mobile/1C28 Safari/419.3',
    'Mechanize' => "Mechanize/#{VERSION} Ruby/#{ruby_version} (http://github.com/tenderlove/mechanize/)"
  }

  # A Mechanize::CookieJar which stores cookies

  def cookie_jar
    @agent.cookie_jar
  end

  def cookie_jar= cookie_jar
    @agent.cookie_jar = cookie_jar
  end

  # Length of time to wait until a connection is opened in seconds
  def open_timeout
    @agent.open_timeout
  end

  def open_timeout= open_timeout
    @agent.open_timeout = open_timeout
  end

  # Length of time to attempt to read data from the server
  def read_timeout
    @agent.read_timeout
  end

  def read_timeout= read_timeout
    @agent.read_timeout = read_timeout
  end

  # The identification string for the client initiating a web request
  def user_agent
    @agent.user_agent
  end

  # The value of watch_for_set is passed to pluggable parsers for retrieved
  # content
  attr_accessor :watch_for_set

  # Path to an OpenSSL server certificate file
  def ca_file
    @agent.ca_file
  end

  def ca_file= ca_file
    @agent.ca_file = ca_file
  end

  def certificate
    @agent.certificate
  end

  # An OpenSSL private key or the path to a private key
  def key
    @agent.key
  end

  def key= key
    @agent.key = key
  end

  # An OpenSSL client certificate or the path to a certificate file.
  def cert
    @agent.cert
  end

  def cert= cert
    @agent.cert = cert
  end

  # OpenSSL key password
  def pass
    @agent.pass
  end

  def pass= pass
    @agent.pass = pass
  end

  # Controls how this agent deals with redirects.  The following values are
  # allowed:
  #
  # :all, true:: All 3xx redirects are followed (default)
  # :permanent:: Only 301 Moved Permanantly redirects are followed
  # false:: No redirects are followed

  def redirect_ok
    @agent.redirect_ok
  end

  def redirect_ok= follow
    @agent.redirect_ok = follow
  end

  def gzip_enabled
    @agent.gzip_enabled
  end

  # Disables HTTP/1.1 gzip compression (enabled by default)
  def gzip_enabled=enabled
    @agent.gzip_enabled = enabled
  end

  def conditional_requests
    @agent.conditional_requests
  end

  # Disables If-Modified-Since conditional requests (enabled by default)
  def conditional_requests= enabled
    @agent.conditional_requests = enabled
  end

  # Follow HTML meta refresh.  If set to +:anywhere+ meta refresh tags outside
  # of the head element will be followed.
  def follow_meta_refresh
    @agent.follow_meta_refresh
  end

  def follow_meta_refresh= follow
    @agent.follow_meta_refresh = follow
  end

  # A callback for additional certificate verification.  See
  # OpenSSL::SSL::SSLContext#verify_callback
  #
  # The callback can be used for debugging or to ignore errors by always
  # returning +true+.  Specifying nil uses the default method that was valid
  # when the SSLContext was created
  def verify_callback
    @agent.verify_callback
  end

  def verify_callback= verify_callback
    @agent.verify_callback = verify_callback
  end

  attr_accessor :history_added

  def redirection_limit
    @agent.redirection_limit
  end

  def redirection_limit= limit
    @agent.redirection_limit = limit
  end

  def scheme_handlers
    @agent.scheme_handlers
  end

  def scheme_handlers= scheme_handlers
    @agent.scheme_handlers = scheme_handlers
  end

  # A hash of custom request headers
  def request_headers
    @agent.request_headers
  end

  def request_headers= request_headers
    @agent.request_headers = request_headers
  end

  # Proxy settings
  attr_reader :proxy_addr
  attr_reader :proxy_pass
  attr_reader :proxy_port
  attr_reader :proxy_user

  # The HTML parser to be used when parsing documents
  attr_accessor :html_parser

  attr_reader :agent # :nodoc:

  def history
    @agent.history
  end

  attr_reader :pluggable_parser

  # A list of hooks to call after retrieving a response.  Hooks are called with
  # the agent and the response returned.

  def post_connect_hooks
    @agent.post_connect_hooks
  end

  # A list of hooks to call before making a request.  Hooks are called with
  # the agent and the request to be performed.

  def pre_connect_hooks
    @agent.pre_connect_hooks
  end

  # An array of hooks(Proc objects) to #call before reading response header 'content-encoding'.
  #    agent.content_encoding_hooks << lambda{|httpagent, uri, http_response, response_body_io| ... }
  def content_encoding_hooks
    @agent.content_encoding_hooks
  end

  alias follow_redirect? redirect_ok

  @html_parser = Nokogiri::HTML
  class << self
    attr_accessor :html_parser, :log

    def inherited(child)
      child.html_parser ||= html_parser
      child.log ||= log
      super
    end
  end

  # A default encoding name used when parsing HTML parsing.  When set it is
  # used after any other encoding.  The default is nil.

  attr_accessor :default_encoding

  # Overrides the encodings given by the HTTP server and the HTML page with
  # the default_encoding when set to true.
  attr_accessor :force_default_encoding

  def initialize
    @agent = Mechanize::HTTP::Agent.new
    @agent.context = self

    # attr_accessors
    @agent.user_agent = AGENT_ALIASES['Mechanize']
    @watch_for_set    = nil
    @history_added    = nil

    # attr_readers
    @pluggable_parser = PluggableParser.new

    @keep_alive       = true
    @keep_alive_time  = 0

    # Proxy
    @proxy_addr = nil
    @proxy_port = nil
    @proxy_user = nil
    @proxy_pass = nil

    @html_parser = self.class.html_parser

    @default_encoding = nil
    @force_default_encoding = false

    yield self if block_given?

    @agent.set_proxy @proxy_addr, @proxy_port, @proxy_user, @proxy_pass
    @agent.set_http
  end

  def max_history
    @agent.history.max_size
  end

  def max_history= length
    @agent.history.max_size = length
  end

  def log=(l); Mechanize.log = l end
  def log; Mechanize.log end

  def user_agent= user_agent
    @agent.user_agent = user_agent
  end

  # Set the user agent for the Mechanize object.  See AGENT_ALIASES
  def user_agent_alias=(al)
    self.user_agent = AGENT_ALIASES[al] ||
      raise(ArgumentError, "unknown agent alias #{al.inspect}")
  end

  # Returns a list of cookies stored in the cookie jar.
  def cookies
    @agent.cookie_jar.to_a
  end

  # Sets the user and password to be used for authentication.
  def auth(user, password)
    @agent.user     = user
    @agent.password = password
  end

  alias :basic_auth :auth

  # Fetches the URL passed in and returns a page.
  def get(uri, parameters = [], referer = nil, headers = {})
    method = :get

    if Hash === uri then
      options = uri
      location = Gem.location_of_caller.join ':'
      warn "#{location}: Mechanize#get with options hash is deprecated and will be removed October 2011"

      raise ArgumentError, "url must be specified" unless uri = options[:url]
      parameters = options[:params] || []
      referer    = options[:referer]
      headers    = options[:headers]
      method     = options[:verb] || method
    end

    referer ||=
      if uri.to_s =~ %r{\Ahttps?://}
        Page.new(nil, {'content-type'=>'text/html'})
      else
        current_page || Page.new(nil, {'content-type'=>'text/html'})
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
    headers ||= {}
    page = @agent.fetch uri, method, headers, parameters, referer
    add_to_history(page)
    yield page if block_given?
    page
  end

  ##
  # PUT to +url+ with +entity+, and setting +headers+:
  #
  #   put('http://example/', 'new content', {'Content-Type' => 'text/plain'})
  #
  def put(url, entity, headers = {})
    request_with_entity(:put, url, entity, headers)
  end

  ##
  # DELETE to +url+ with +query_params+, and setting +headers+:
  #
  #   delete('http://example/', {'q' => 'foo'}, {})
  #
  def delete(uri, query_params = {}, headers = {})
    page = @agent.fetch(uri, :delete, headers, query_params)
    add_to_history(page)
    page
  end

  ##
  # HEAD to +url+ with +query_params+, and setting +headers+:
  #
  #   head('http://example/', {'q' => 'foo'}, {})
  #
  def head(uri, query_params = {}, headers = {})
    # fetch the page
    page = @agent.fetch(uri, :head, headers, query_params)
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
    when Page::Link
      referer = link.page || current_page()
      if @agent.robots
        if (referer.is_a?(Page) && referer.parser.nofollow?) || link.rel?('nofollow')
          raise RobotsDisallowedError.new(link.href)
        end
      end
      if link.rel?('noreferrer')
        href = @agent.resolve(link.href, link.page || current_page)
        referer = Page.new(nil, {'content-type'=>'text/html'})
      else
        href = link.href
      end
      get href, [], referer
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
      referer = current_page()
      href = link.respond_to?(:href) ? link.href :
        (link['href'] || link['src'])
      get href, [], referer
    end
  end

  # Equivalent to the browser back button.  Returns the most recent page
  # visited.
  def back
    @agent.history.pop
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
      return request_with_entity(:post, url, query, headers)
    end
    node = {}
    # Create a fake form
    class << node
      def search(*args); []; end
    end
    node['method'] = 'POST'
    node['enctype'] = 'application/x-www-form-urlencoded'

    form = Form.new(node)

    query.each { |k, v|
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
      get(form.action.gsub(/\?[^\?]*$/, ''),
          form.build_query,
          form.page,
          headers)
    else
      raise ArgumentError, "unsupported method: #{form.method.upcase}"
    end
  end

  def request_with_entity(verb, uri, entity, headers = {})
    cur_page = current_page || Page.new(nil, {'content-type'=>'text/html'})

    headers = {
      'Content-Type' => 'application/octet-stream',
      'Content-Length' => entity.size.to_s,
    }.update headers

    page = @agent.fetch uri, verb, headers, [entity], cur_page
    add_to_history(page)
    page
  end

  # Returns the current page loaded by Mechanize
  def current_page
    @agent.current_page
  end

  # Returns a visited page for the url passed in, otherwise nil
  def visited_page(url)
    url = url.href if url.respond_to? :href

    @agent.visited_page url
  end

  # Returns whether or not a url has been visited
  alias visited? visited_page

  def parse uri, response, body
    content_type = nil

    unless response['Content-Type'].nil?
      data, = response['Content-Type'].split ';', 2
      content_type, = data.downcase.split ',', 2 unless data.nil?
    end

    # Find our pluggable parser
    parser_klass = @pluggable_parser.parser content_type

    parser_klass.new uri, response, body, response.code do |parser|
      parser.mech = self if parser.respond_to? :mech=

      parser.watch_for_set = @watch_for_set if
        @watch_for_set and parser.respond_to?(:watch_for_set=)
    end
  end

  ##
  # Sets the proxy +address+ at +port+ with an optional +user+ and +password+

  def set_proxy address, port, user = nil, password = nil
    @proxy_addr = address
    @proxy_port = port
    @proxy_user = user
    @proxy_pass = password

    @agent.set_proxy address, port, user, password
    @agent.set_http
  end

  # Runs given block, then resets the page history as it was before. self is
  # given as a parameter to the block. Returns the value of the block.
  def transact
    history_backup = @agent.history.dup
    begin
      yield self
    ensure
      @agent.history = history_backup
    end
  end

  def robots
    @agent.robots
  end

  def robots= enabled
    @agent.robots = enabled
  end

  alias :page :current_page

  private

  def post_form(uri, form, headers = {})
    cur_page = form.page || current_page ||
      Page.new(nil, {'content-type'=>'text/html'})

    request_data = form.request_data

    log.debug("query: #{ request_data.inspect }") if log

    headers = {
      'Content-Type'    => form.enctype,
      'Content-Length'  => request_data.size.to_s,
    }.merge headers

    # fetch the page
    page = @agent.fetch uri, :post, headers, [request_data], cur_page
    add_to_history(page)
    page
  end

  def add_to_history(page)
    @agent.history.push(page, @agent.resolve(page.uri))
    @history_added.call(page) if @history_added
  end

end

require 'mechanize/content_type_error'
require 'mechanize/cookie'
require 'mechanize/cookie_jar'
require 'mechanize/file'
require 'mechanize/file_connection'
require 'mechanize/file_request'
require 'mechanize/file_response'
require 'mechanize/form'
require 'mechanize/history'
require 'mechanize/http'
require 'mechanize/http/agent'
require 'mechanize/page'
require 'mechanize/inspect'
require 'mechanize/monkey_patch'
require 'mechanize/pluggable_parsers'
require 'mechanize/redirect_limit_reached_error'
require 'mechanize/redirect_not_get_or_head_error'
require 'mechanize/response_code_error'
require 'mechanize/response_read_error'
require 'mechanize/robots_disallowed_error'
require 'mechanize/unsupported_scheme_error'
require 'mechanize/util'

