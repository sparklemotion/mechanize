# Original Code: 
# Copyright (c) 2005 by Michael Neumann (mneumann@ntecs.de) 
#
# New Code:
# Copyright (c) 2006 by Aaron Patterson (aaronp@rubyforge.org) 
#
# Please see the LICENSE file for licensing.
#

# required due to the missing get_fields method in Ruby 1.8.2
unless RUBY_VERSION > "1.8.2"
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "mechanize", "net-overrides")
end
require 'net/http'
require 'net/https'

require 'uri'
require 'webrick'
require 'zlib'
require 'stringio'
require 'web/htmltools/xmltree'   # narf
require 'mechanize/module'
require 'mechanize/mech_version'
require 'mechanize/cookie'
require 'mechanize/errors'
require 'mechanize/pluggable_parsers'
require 'mechanize/form'
require 'mechanize/form_elements'
require 'mechanize/list'
require 'mechanize/page'
require 'mechanize/page_elements'
require 'mechanize/parsing'
require 'mechanize/inspect'

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
  AGENT_ALIASES = {
    'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/418 (KHTML, like Gecko) Safari/417.9.3',
    'Mac FireFox' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.8.0.3) Gecko/20060426 Firefox/1.5.0.3',
    'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
    'Mechanize' => "WWW-Mechanize/#{Version} (http://rubyforge.org/projects/mechanize/)"
  }

  attr_accessor :cookie_jar
  attr_accessor :log
  attr_accessor :max_history
  attr_accessor :open_timeout, :read_timeout
  attr_accessor :user_agent
  attr_accessor :watch_for_set
  attr_accessor :ca_file
  attr_accessor :key
  attr_accessor :cert
  attr_accessor :pass

  attr_reader :history
  attr_reader :pluggable_parser

  def initialize
    # attr_accessors
    @cookie_jar = CookieJar.new
    @log = Logger.new(nil)
    @max_history    = nil
    @open_timeout   = nil
    @read_timeout   = nil
    @user_agent     = AGENT_ALIASES['Mechanize']
    @watch_for_set  = nil
    @ca_file        = nil
    @cert           = nil # OpenSSL Certificate
    @key            = nil # OpenSSL Private Key
    @pass           = nil # OpenSSL Password
    
    # attr_readers
    @history        = []
    @pluggable_parser = PluggableParser.new

    # Basic Auth variables
    @user           = nil # Basic Auth User
    @password       = nil # Basic Auth Password

    # Proxy settings
    @proxy_addr     = nil
    @proxy_pass     = nil
    @proxy_port     = nil
    @proxy_user     = nil

    yield self if block_given?
  end

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
    @user = user
    @password = password
  end

  # Fetches the URL passed in and returns a page.
  def get(url)
    cur_page = current_page || Page.new( nil, {'content-type'=>'text/html'})

    # fetch the page
    abs_uri = to_absolute_uri(url, cur_page)
    request = fetch_request(abs_uri)
    page = fetch_page(abs_uri, request, cur_page)
    add_to_history(page)
    page
  end

  # Fetch a file and return the contents of the file.
  def get_file(url)
    get(url).body
  end


  # Clicks the WWW::Mechanize::Link object passed in and returns the
  # page fetched.
  def click(link)
    uri = to_absolute_uri(
      link.attributes['href'] || link.attributes['src'] || link.href
    )
    get(uri)
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
    node.attributes = {}
    node.attributes['method'] = 'POST'
    node.attributes['enctype'] = 'application/x-www-form-urlencoded'

    form = Form.new(node)
    query.each { |k,v|
      form.fields << Field.new(k,v)
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
    uri = to_absolute_uri(form.action)
    case form.method.upcase
    when 'POST'
      post_form(uri, form) 
    when 'GET'
      if uri.query.nil?
        uri.query = WWW::Mechanize.build_query_string(form.build_query)
      else
        uri.query = uri.query + "&" +
          WWW::Mechanize.build_query_string(form.build_query)
      end
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
    if url.is_a?(Link)
      url = url.uri
    end
    uri = to_absolute_uri(url)
    ! @history.find { |h| h.uri.to_s == uri.to_s }.nil?
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

  def to_absolute_uri(url, cur_page=current_page())
    if url.is_a?(URI)
      uri = url
    else
      uri = URI.parse(url.strip.gsub(/\s/, '%20'))
    end

    # construct an absolute uri
    if uri.relative?
      if cur_page.uri
        uri = cur_page.uri + (url.is_a?(URI) ? url : URI::escape(url.strip))
      else
        raise 'no history. please specify an absolute URL'
      end
    end

    return uri
  end

  def post_form(url, form)
    cur_page = current_page || Page.new(nil, {'content-type'=>'text/html'})

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
    raise "unsupported scheme" unless ['http', 'https'].include?(uri.scheme)
    if type == :get
      Net::HTTP::Get.new(uri.request_uri)
    else
      Net::HTTP::Post.new(uri.request_uri)
    end
  end

  # uri is an absolute URI
  def fetch_page(uri, request, cur_page=current_page(), request_data=[])
    raise "unsupported scheme" unless ['http', 'https'].include?(uri.scheme)

    log.info("#{ request.class }: #{ uri.to_s }") if log

    page = nil

    http_obj = Net::HTTP.new( uri.host,
                          uri.port,
                          @proxy_addr,
                          @proxy_port,
                          @proxy_user,
                          @proxy_pass
                        )

    if uri.scheme == 'https'
      http_obj.use_ssl = true
      http_obj.verify_mode = OpenSSL::SSL::VERIFY_NONE
      if @ca_file
        http_obj.ca_file = @ca_file
        http_obj.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
      if @cert && @key
        http_obj.cert = OpenSSL::X509::Certificate.new(::File.read(@cert))
        http_obj.key  = OpenSSL::PKey::RSA.new(::File.read(@key), @pass)
      end
    end

    request.add_field('Accept-Encoding', 'gzip,identity')

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

    request.basic_auth(@user, @password) if @user

    # Log specified headers for the request
    if log
      request.each_header do |k, v|
        log.debug("request-header: #{ k } => #{ v }")
      end
    end

    http_obj.start { |http|
      # Specify timeouts if given
      http.open_timeout = @open_timeout if @open_timeout
      http.read_timeout = @read_timeout if @read_timeout

      # Send the request
      http.request(request, *request_data) {|response|
        (response.get_fields('Set-Cookie')||[]).each do |cookie|
          log.debug("cookie received: #{ cookie }") 
          Cookie::parse(uri, cookie) { |c| @cookie_jar.add(c) }
        end

        response.each_header {|k,v|
          log.debug("header: #{ k } : #{ v }")
        }

        response.read_body

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
            Zlib::GzipReader.new(StringIO.new(response.body)).read
          else
            raise 'Unsupported content encoding'
          end
        else
          response.body
        end

        # Find our pluggable parser
        page = @pluggable_parser.parser(content_type).new(
          uri,
          response,
          response_body,
          response.code
        )

        log.info("status: #{ page.code }")

        if page.respond_to? :watch_for_set
          page.watch_for_set = @watch_for_set
        end

        case page.code
        when "200"
          return page
        when "301", "302"
          log.info("follow redirect to: #{ response['Location'] }")
          abs_uri = to_absolute_uri(
            URI.parse(
              URI.escape(URI.unescape(response['Location'].to_s))), page)
          request = fetch_request(abs_uri)
          return fetch_page(abs_uri, request, page)
        else
          raise ResponseCodeError.new(page.code), "Unhandled response", caller
        end
      }
    }
  end

  def self.build_query_string(parameters)
    vals = [] 
    parameters.each { |k,v|
      next if k.nil?
      vals <<
      [WEBrick::HTTPUtils.escape_form(k), 
       WEBrick::HTTPUtils.escape_form(v.to_s)].join("=")
    }

    vals.join("&")
  end

  def add_to_history(page)
    @history.push(page)
    if @max_history and @history.size > @max_history
      # keep only the last @max_history entries
      @history = @history[@history.size - @max_history, @max_history] 
    end
  end
end

end # module WWW
