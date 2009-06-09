require 'net/http'
require 'net/https'
require 'uri'
require 'webrick/httputils'
require 'zlib'
require 'stringio'
require 'digest/md5'
require 'fileutils'
require 'nokogiri'
require 'forwardable'
require 'iconv'
require 'nkf'

require 'www/mechanize/util'
require 'www/mechanize/content_type_error'
require 'www/mechanize/response_code_error'
require 'www/mechanize/unsupported_scheme_error'
require 'www/mechanize/redirect_limit_reached_error'
require 'www/mechanize/redirect_not_get_or_head_error'
require 'www/mechanize/cookie'
require 'www/mechanize/cookie_jar'
require 'www/mechanize/history'
require 'www/mechanize/form'
require 'www/mechanize/pluggable_parsers'
require 'www/mechanize/file_response'
require 'www/mechanize/inspect'
require 'www/mechanize/chain'
require 'www/mechanize/monkey_patch'

module WWW
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
  #  agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
  #  agent.user_agent_alias = 'Mac Safari'
  #  page = agent.get("http://www.google.com/")
  #  search_form = page.form_with(:name => "f")
  #  search_form.field_with(:name => "q").value = "Hello"
  #  search_results = agent.submit(search_form)
  #  puts search_results.body
  class Mechanize
    ##
    # The version of Mechanize you are using.
    VERSION = '0.9.3'

    ##
    # User Agent aliases
    AGENT_ALIASES = {
      'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
      'Windows IE 7' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET CLR 1.1.4322; .NET CLR 2.0.50727)',
      'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
      'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418 (KHTML, like Gecko) Safari/417.9.3',
      'Mac FireFox' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.3) Gecko/20060426 Firefox/1.5.0.3',
      'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
      'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
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
    attr_accessor :redirect_ok
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

    # The HTML parser to be used when parsing documents
    attr_accessor :html_parser

    attr_reader :history
    attr_reader :pluggable_parser

    alias :follow_redirect? :redirect_ok

    @html_parser = Nokogiri::HTML
    class << self; attr_accessor :html_parser, :log end

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
      @redirect_ok    = true # Should we follow redirects?

      # attr_readers
      @history        = WWW::Mechanize::History.new
      @pluggable_parser = PluggableParser.new

      # Auth variables
      @user           = nil # Auth User
      @password       = nil # Auth Password
      @digest         = nil # DigestAuth Digest
      @auth_hash      = {}  # Keep track of urls for sending auth
      @request_headers= {}  # A hash of request headers to be used

      # Proxy settings
      @proxy_addr     = nil
      @proxy_pass     = nil
      @proxy_port     = nil
      @proxy_user     = nil

      @conditional_requests = true

      @follow_meta_refresh  = false
      @redirection_limit    = 20

      # Connection Cache & Keep alive
      @connection_cache = {}
      @keep_alive_time  = 300
      @keep_alive       = true

      @scheme_handlers  = Hash.new { |h,k|
        h[k] = lambda { |link, page|
          raise UnsupportedSchemeError.new(k)
        }
      }
      @scheme_handlers['http']      = lambda { |link, page| link }
      @scheme_handlers['https']     = @scheme_handlers['http']
      @scheme_handlers['relative']  = @scheme_handlers['http']
      @scheme_handlers['file']      = @scheme_handlers['http']

      @pre_connect_hook = Chain::PreConnectHook.new
      @post_connect_hook = Chain::PostConnectHook.new

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
      @proxy_addr, @proxy_port, @proxy_user, @proxy_pass = addr, port, user, pass
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
      unless options.is_a? Hash
        url = options
        unless parameters.respond_to?(:each) # FIXME: Remove this in 0.8.0
          referer = parameters
          parameters = []
        end
      else
        raise ArgumentError.new("url must be specified") unless url = options[:url]
        parameters = options[:params] || []
        referer = options[:referer]
        headers = options[:headers]
      end

      unless referer
        if url.to_s =~ /^http/
          referer = Page.new(nil, {'content-type'=>'text/html'})
        else
          referer = current_page || Page.new(nil, {'content-type'=>'text/html'})
        end
      end

      # FIXME: Huge hack so that using a URI as a referer works.  I need to
      # refactor everything to pass around URIs but still support
      # WWW::Mechanize::Page#base
      unless referer.is_a?(WWW::Mechanize::File)
        referer = referer.is_a?(String) ?
          Page.new(URI.parse(referer), {'content-type' => 'text/html'}) :
          Page.new(referer, {'content-type' => 'text/html'})
      end

      # fetch the page
      page = fetch_page(  :uri      => url,
                          :referer  => referer,
                          :headers  => headers || {},
                          :params   => parameters
                       )
      add_to_history(page)
      yield page if block_given?
      page
    end

    ####
    # PUT to +url+ with +query_params+, and setting +options+:
    #
    #   put('http://tenderlovemaking.com/', {'q' => 'foo'}, :headers => {})
    #
    def put(url, query_params = {}, options = {})
      page = head(url, query_params, options.merge({:verb => :put}))
      add_to_history(page)
      page
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

    # Clicks the WWW::Mechanize::Link object passed in and returns the
    # page fetched.
    def click(link)
      referer = link.page rescue referer = nil
      href = link.respond_to?(:href) ? link.href :
        (link['href'] || link['src'])
      get(:url => href, :referer => (referer || current_page()))
    end

    # Equivalent to the browser back button.  Returns the most recent page
    # visited.
    def back
      @history.pop
    end

    # Posts to the given URL wht the query parameters passed in.  Query
    # parameters can be passed as a hash, or as an array of arrays.
    # Example:
    #  agent.post('http://example.com/', "foo" => "bar")
    # or
    #  agent.post('http://example.com/', [ ["foo", "bar"] ])
    def post(url, query={})
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
          ul = Form::FileUpload.new(k.to_s,::File.basename(v.path))
          ul.file_data = v.read
          form.file_uploads << ul
        else
          form.fields << Form::Field.new(k.to_s,v)
        end
      }
      post_form(url, form)
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
      chain = Chain.new([
        Chain::URIResolver.new(@scheme_handlers)
      ]).handle(hash)
      hash[:uri].to_s
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
        Chain::URIResolver.new(@scheme_handlers),
        Chain::ParameterResolver.new,
        Chain::RequestResolver.new,
        Chain::ConnectionResolver.new(
          @connection_cache,
          @keep_alive,
          @proxy_addr,
          @proxy_port,
          @proxy_user,
          @proxy_pass
        ),
        Chain::SSLResolver.new(@ca_file, @verify_callback, @cert, @key, @pass),
        Chain::AuthHeaders.new(@auth_hash, @user, @password, @digest),
        Chain::HeaderResolver.new(
          @keep_alive,
          @keep_alive_time,
          @cookie_jar,
          @user_agent,
          {}
        ),
        Chain::CustomHeaders.new,
        @pre_connect_hook,
      ])
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
      http_obj.start unless http_obj.started?

      # Log specified headers for the request
      log.info("#{ request.class }: #{ request.path }") if log
      request.each_header do |k, v|
        log.debug("request-header: #{ k } => #{ v }")
      end if log

      # Send the request
      attempts = 0
      begin
        response = http_obj.request(request, *request_data) { |r|
          connection_chain = Chain.new([
            Chain::ResponseReader.new(r),
            Chain::BodyDecodingHandler.new,
          ])
          connection_chain.handle(options)
        }
      rescue EOFError, Errno::ECONNRESET, Errno::EPIPE => x
        log.error("Rescuing EOF error") if log
        http_obj.finish
        raise x if attempts >= 2
        request.body = nil
        http_obj.start
        attempts += 1
        retry
      end

      after_connect = Chain.new([
        @post_connect_hook,
        Chain::ResponseBodyParser.new(@pluggable_parser, @watch_for_set),
        Chain::ResponseHeaderHandler.new(@cookie_jar, @connection_cache),
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
        return page unless follow_redirect?
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
end
