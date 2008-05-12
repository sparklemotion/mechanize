require 'net/http'
require 'net/https'
require 'uri'
require 'webrick/httputils'
require 'zlib'
require 'stringio'
require 'digest/md5'

require 'www/mechanize/content_type_error'
require 'www/mechanize/response_code_error'
require 'www/mechanize/cookie'
require 'www/mechanize/cookie_jar'
require 'www/mechanize/history'
require 'www/mechanize/list'
require 'www/mechanize/form'
require 'www/mechanize/pluggable_parsers'
require 'www/mechanize/inspect'
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
  #  search_form = page.forms.name("f").first
  #  search_form.fields.name("q").value = "Hello"
  #  search_results = agent.submit(search_form)
  #  puts search_results.body
  class Mechanize
    ##
    # The version of Mechanize you are using.
    VERSION = '0.7.5'
  
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
    attr_accessor :log
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
  
    attr_reader :history
    attr_reader :pluggable_parser
  
    alias :follow_redirect? :redirect_ok
  
    @@nonce_count = -1
    CNONCE = Digest::MD5.hexdigest("%x" % (Time.now.to_i + rand(65535)))
  
    def initialize
      # attr_accessors
      @cookie_jar     = CookieJar.new
      @log            = nil
      @open_timeout   = nil
      @read_timeout   = nil
      @user_agent     = AGENT_ALIASES['Mechanize']
      @watch_for_set  = nil
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
      @digest_response = nil
  
      # Proxy settings
      @proxy_addr     = nil
      @proxy_pass     = nil
      @proxy_port     = nil
      @proxy_user     = nil
  
      @conditional_requests = true
  
      @follow_meta_refresh  = false
  
      # Connection Cache & Keep alive
      @connection_cache = {}
      @keep_alive_time  = 300
      @keep_alive       = true
  
      yield self if block_given?
    end
  
    def max_history=(length); @history.max_size = length; end
    def max_history; @history.max_size; end
  
    # Sets the proxy address, port, user, and password
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
  
    # Sets the user and password to be used for basic authentication.
    def basic_auth(user, password)
      auth(user, password)
    end
  
    def auth(user, password)
      @user       = user
      @password   = password
    end
  
    # Fetches the URL passed in and returns a page.
    def get(url, parameters = [], referer = nil)
      unless parameters.respond_to?(:each) # FIXME: Remove this in 0.8.0
        referer = parameters
        parameters = []
      end

      referer ||= current_page || Page.new(nil, {'content-type'=>'text/html'})

      # FIXME: Huge hack so that using a URI as a referer works.  I need to
      # refactor everything to pass around URIs but still support
      # WWW::Mechanize::Page#base
      unless referer.is_a?(WWW::Mechanize::File)
        referer = referer.is_a?(String) ?
          Page.new(URI.parse(referer), {'content-type' => 'text/html'}) :
          Page.new(referer, {'content-type' => 'text/html'})
      end
      abs_uri = to_absolute_uri(url, referer)

      if parameters.length > 0
        abs_uri.query ||= ''
        abs_uri.query << '&' if abs_uri.query.length > 0
        abs_uri.query << self.class.build_query_string(parameters)
      end

      # fetch the page
      request = fetch_request(abs_uri)
      page = fetch_page(abs_uri, request, referer)
      add_to_history(page)
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
      referer =
        begin
          link.page
        rescue
          nil
        end
      uri = to_absolute_uri(
        link.attributes['href'] || link.attributes['src'] || link.href,
        referer || current_page()
      )
      get(uri, referer)
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
      node = Hpricot::Elem.new(Hpricot::STag.new('form'))
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
    def submit(form, button=nil)
      form.add_button_to_query(button) if button
      uri = to_absolute_uri(form.action, form.page)
      case form.method.upcase
      when 'POST'
        post_form(uri, form) 
      when 'GET'
        uri.query = WWW::Mechanize.build_query_string(form.build_query)
        get(uri)
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
      @history.visited_page(to_absolute_uri(url))
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

    class << self
      def html_unescape(s)
        return s unless s
        s.gsub(/&(\w+|#[0-9]+);/) { |match|
          number = case match
          when /&(\w+);/
            Hpricot::NamedCharacters[$1]
          when /&#([0-9]+);/
            $1.to_i
          end
  
          number ? ([number].pack('U') rescue match) : match
        }
      end
    end
  
    protected
    def set_headers(uri, request, cur_page)
      if @keep_alive
        request.add_field('Connection', 'keep-alive')
        request.add_field('Keep-Alive', keep_alive_time.to_s)
      else
        request.add_field('Connection', 'close')
      end
      request.add_field('Accept-Encoding', 'gzip,identity')
      request.add_field('Accept-Language', 'en-us,en;q=0.5')
      request.add_field('Accept-Charset', 'ISO-8859-1,utf-8;q=0.7,*;q=0.7')
  
      unless @cookie_jar.empty?(uri)
        cookies = @cookie_jar.cookies(uri)
        cookie = cookies.length > 0 ? cookies.join("; ") : nil
        if log
          cookies.each do |c|
            log.debug("using cookie: #{c}")
          end
        end
        request.add_field('Cookie', cookie)
      end
  
      # Add Referer header to request
      unless cur_page.uri.nil?
        request.add_field('Referer', cur_page.uri.to_s)
      end
  
      # Add User-Agent header to request
      request.add_field('User-Agent', @user_agent) if @user_agent 
  
      # Add If-Modified-Since if page is in history
      if @conditional_requests
        if( (page = visited_page(uri)) && page.response['Last-Modified'] )
          request.add_field('If-Modified-Since', page.response['Last-Modified'])
        end
      end
  
      if( @auth_hash[uri.host] )
        case @auth_hash[uri.host]
        when :basic
          request.basic_auth(@user, @password)
        when :digest
          @digest_response = self.gen_auth_header(uri,request,@digest) if @digest
          request.add_field('Authorization', @digest_response) if @digest_response
        end
      end
  
      request
    end
  
    def gen_auth_header(uri, request, auth_header, is_IIS = false)
      @@nonce_count += 1
  
      user = @digest_user
      password = @digest_password
  
      auth_header =~ /^(\w+) (.*)/
  
      params = {}
      $2.gsub(/(\w+)="(.*?)"/) { params[$1] = $2 }
  
      a_1 = "#{@user}:#{params['realm']}:#{@password}"
      a_2 = "#{request.method}:#{uri.path}"
      request_digest = ''
      request_digest << Digest::MD5.hexdigest(a_1)
      request_digest << ':' << params['nonce']
      request_digest << ':' << ('%08x' % @@nonce_count)
      request_digest << ':' << CNONCE
      request_digest << ':' << params['qop']
      request_digest << ':' << Digest::MD5.hexdigest(a_2)
  
      header = ''
      header << "Digest username=\"#{@user}\", "
      header << "realm=\"#{params['realm']}\", "
      if is_IIS then
        header << "qop=\"#{params['qop']}\", "
      else
        header << "qop=#{params['qop']}, "
      end
      header << "uri=\"#{uri.path}\", "
      header << "algorithm=MD5, "
      header << "nonce=\"#{params['nonce']}\", "
      header << "nc=#{'%08x' % @@nonce_count}, "
      header << "cnonce=\"#{CNONCE}\", "
      header << "response=\"#{Digest::MD5.hexdigest(request_digest)}\""
  
      return header
    end
  
    private
  
    def to_absolute_uri(url, cur_page=current_page())
      unless url.is_a? URI
        url = url.to_s.strip.gsub(/[^#{0.chr}-#{126.chr}]/) { |match|
          sprintf('%%%X', match.unpack($KCODE == 'UTF8' ? 'U' : 'c')[0])
        }
  
        url = URI.parse(
                Mechanize.html_unescape(
                  url.split(/%[0-9A-Fa-f]{2}|#/).zip(
                    url.scan(/%[0-9A-Fa-f]{2}|#/)
                  ).map { |x,y|
                    "#{URI.escape(x)}#{y}"
                  }.join('')
                )
              )
      end
  
      url.path = '/' if url.path.length == 0
  
      # construct an absolute uri
      if url.relative?
        raise 'no history. please specify an absolute URL' unless cur_page.uri
        base = cur_page.respond_to?(:bases) ? cur_page.bases.last : nil
        url = ((base && base.uri && base.uri.absolute?) ?
                base.uri :
                cur_page.uri) + url
        url = cur_page.uri + url
        # Strip initial "/.." bits from the path
        url.path.sub!(/^(\/\.\.)+(?=\/)/, '')
      end
  
      return url
    end
  
    def post_form(url, form)
      cur_page = form.page || current_page ||
                      Page.new( nil, {'content-type'=>'text/html'})
  
      request_data = form.request_data
  
      abs_url = to_absolute_uri(url, cur_page)
      request = fetch_request(abs_url, :post)
      request.add_field('Content-Type', form.enctype)
      request.add_field('Content-Length', request_data.size.to_s)
  
      log.debug("query: #{ request_data.inspect }") if log
  
      # fetch the page
      page = fetch_page(abs_url, request, cur_page, [request_data])
      add_to_history(page) 
      page
    end
  
    # Creates a new request object based on the scheme and type
    def fetch_request(uri, type = :get)
      raise "unsupported scheme: #{uri.scheme}" unless ['http', 'https'].include?(uri.scheme.downcase)
      if type == :get
        Net::HTTP::Get.new(uri.request_uri)
      else
        Net::HTTP::Post.new(uri.request_uri)
      end
    end
  
    # uri is an absolute URI
    def fetch_page(uri, request, cur_page=current_page(), request_data=[])
      raise "unsupported scheme: #{uri.scheme}" unless ['http', 'https'].include?(uri.scheme.downcase)
  
      log.info("#{ request.class }: #{ request.path }") if log
  
      page = nil
  
      cache_obj = (@connection_cache["#{uri.host}:#{uri.port}"] ||= {
        :connection         => nil,
        :keep_alive_options => {},
      })
      http_obj = cache_obj[:connection]
      if http_obj.nil? || ! http_obj.started?
        http_obj = cache_obj[:connection] =
            Net::HTTP.new( uri.host,
                    uri.port,
                    @proxy_addr,
                    @proxy_port,
                    @proxy_user,
                    @proxy_pass
                  )
        cache_obj[:keep_alive_options] = {}
  
        # Specify timeouts if given
        http_obj.open_timeout = @open_timeout if @open_timeout
        http_obj.read_timeout = @read_timeout if @read_timeout
      end
  
      if uri.scheme == 'https' && ! http_obj.started?
        http_obj.use_ssl = true
        http_obj.verify_mode = OpenSSL::SSL::VERIFY_NONE
        if @ca_file
          http_obj.ca_file = @ca_file
          http_obj.verify_mode = OpenSSL::SSL::VERIFY_PEER
          http_obj.verify_callback = @verify_callback if @verify_callback
        end
        if @cert && @key
          http_obj.cert = OpenSSL::X509::Certificate.new(::File.read(@cert))
          http_obj.key  = OpenSSL::PKey::RSA.new(::File.read(@key), @pass)
        end
      end
  
      # If we're keeping connections alive and the last request time is too
      # long ago, stop the connection.  Or, if the max requests left is 1,
      # reset the connection.
      if @keep_alive && http_obj.started?
        opts = cache_obj[:keep_alive_options]
        if((opts[:timeout] &&
           Time.now.to_i - cache_obj[:last_request_time] > opts[:timeout].to_i) ||
            opts[:max] && opts[:max].to_i == 1)
  
          log.debug('Finishing stale connection') if log
          http_obj.finish
  
        end
      end
  
      http_obj.start unless http_obj.started?
  
      request = set_headers(uri, request, cur_page)
  
      # Log specified headers for the request
      if log
        request.each_header do |k, v|
          log.debug("request-header: #{ k } => #{ v }")
        end
      end
  
      cache_obj[:last_request_time] = Time.now.to_i
  
      # Send the request
      begin
        response = http_obj.request(request, *request_data) {|response|
  
          body = StringIO.new
          total = 0
          response.read_body { |part|
            total += part.length
            body.write(part)
            log.debug("Read #{total} bytes") if log
          }
          body.rewind
  
          response.each_header { |k,v|
            log.debug("response-header: #{ k } => #{ v }")
          } if log
  
          content_type = nil
          unless response['Content-Type'].nil?
            data = response['Content-Type'].match(/^([^;]*)/)
            content_type = data[1].downcase unless data.nil?
          end
  
          response_body = 
          if encoding = response['Content-Encoding']
            case encoding.downcase
            when 'gzip'
              log.debug('gunzip body') if log
              if response['Content-Length'].to_i > 0 || body.length > 0
                begin
                  Zlib::GzipReader.new(body).read
                rescue Zlib::BufError => e
                  log.error('Caught a Zlib::BufError') if log
                  body.rewind
                  body.read(10)
                  Zlib::Inflate.new(-Zlib::MAX_WBITS).inflate(body.read)
                end
              else
                ''
              end
            when 'x-gzip'
              body.read
            else
              raise 'Unsupported content encoding'
            end
          else
            body.read
          end
  
          # Find our pluggable parser
          page = @pluggable_parser.parser(content_type).new(
            uri,
            response,
            response_body,
            response.code
          ) { |parser|
            parser.mech = self if parser.respond_to? :mech=
            if parser.respond_to?(:watch_for_set=) && @watch_for_set
              parser.watch_for_set = @watch_for_set
            end
          }
  
        }
      rescue EOFError
        log.error("Rescuing EOF error") if log
        http_obj.finish
        http_obj.start
        retry
      end
  
      # If the server sends back keep alive options, save them
      if keep_alive_info = response['keep-alive']
        keep_alive_info.split(/,\s*/).each do |option|
          k, v = option.split(/=/)
          cache_obj[:keep_alive_options] ||= {}
          cache_obj[:keep_alive_options][k.intern] = v
        end
      end
  
      (response.get_fields('Set-Cookie')||[]).each do |cookie|
        Cookie::parse(uri, cookie, log) { |c|
          log.debug("saved cookie: #{c}") if log
          @cookie_jar.add(uri, c)
        }
      end
  
      log.info("status: #{ page.code }") if log
  
      res_klass = Net::HTTPResponse::CODE_TO_OBJ[page.code.to_s]
  
      if follow_meta_refresh && page.respond_to?(:meta) &&
        (redirect = page.meta.first)
        return redirect.click
      end
  
      return page if res_klass <= Net::HTTPSuccess
  
      if res_klass == Net::HTTPNotModified
        log.debug("Got cached page") if log
        return visited_page(uri)
      elsif res_klass <= Net::HTTPRedirection
        return page unless follow_redirect?
        log.info("follow redirect to: #{ response['Location'] }") if log
        from_uri  = page.uri
        abs_uri   = to_absolute_uri(response['Location'].to_s, page)
        page = fetch_page(abs_uri, fetch_request(abs_uri), page)
        @history.push(page, from_uri)
        return page
      elsif res_klass <= Net::HTTPUnauthorized
        raise ResponseCodeError.new(page) unless @user || @password
        raise ResponseCodeError.new(page) if @auth_hash.has_key?(uri.host)
        if response['www-authenticate'] =~ /Digest/i
          @auth_hash[uri.host] = :digest
          @digest = response['www-authenticate']
        else
          @auth_hash[uri.host] = :basic
        end
        return fetch_page(  uri,
                            fetch_request(uri, request.method.downcase.to_sym),
                            cur_page,
                            request_data
                         )
      end
  
      raise ResponseCodeError.new(page), "Unhandled response", caller
    end
  
    def self.build_query_string(parameters)
      parameters.map { |k,v|
        k &&
          [WEBrick::HTTPUtils.escape_form(k.to_s),
            WEBrick::HTTPUtils.escape_form(v.to_s)].join("=")
      }.compact.join('&')
    end
  
    def add_to_history(page)
      @history.push(page, to_absolute_uri(page.uri))
    end
  end
end
