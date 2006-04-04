# Original Code: 
# Copyright (c) 2005 by Michael Neumann (mneumann@ntecs.de) 
#
# New Code:
# Copyright (c) 2006 by Aaron Patterson (aaronp@rubyforge.org) 
#
# Please see the LICENSE file for licensing.
#

Version = "0.4.1"

# required due to the missing get_fields method in Ruby 1.8.2
unless RUBY_VERSION > "1.8.2"
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "mechanize", "net-overrides")
end
require 'net/http'
require 'net/https'

require 'uri'
require 'logger'
require 'webrick'
require 'date'
require 'web/htmltools/xmltree'   # narf
require 'mechanize/parsing'
require 'mechanize/cookie'
require 'mechanize/form'
require 'mechanize/form_elements'
require 'mechanize/page'
require 'mechanize/page_elements'

module WWW
class ResponseCodeError < RuntimeError
  attr_reader :response_code

  def initialize(response_code)
    @response_code = response_code
  end
end

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
#  search_form = page.forms.find { |f| f.name == "f" }
#  search_form.fields.find { |f| f.name == "q" }.value = "Hello"
#  search_results = agent.submit(search_form)
#  puts search_results.body
class Mechanize

  AGENT_ALIASES = {
    'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
    'Windows Mozilla' => 'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
    'Mac Safari' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
    'Mac Mozilla' => 'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
    'Linux Mozilla' => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
    'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
  }

  attr_accessor :log
  attr_accessor :user_agent
  attr_accessor :cookie_jar
  attr_accessor :open_timeout, :read_timeout
  attr_accessor :watch_for_set
  attr_accessor :max_history
  attr_accessor :ca_file
  attr_reader :history
   
  def initialize
    @history = []
    @cookie_jar = CookieJar.new
    @log = Logger.new(nil)
    yield self if block_given?
  end

  def user_agent_alias=(al)
    self.user_agent = AGENT_ALIASES[al] || raise("unknown agent alias")
  end

  def cookies
    cookies = []
    @cookie_jar.jar.each_key do |domain|
      @cookie_jar.jar[domain].each_key do |name|
        cookies << @cookie_jar.jar[domain][name]
      end
    end
    cookies
  end

  def basic_authetication(user, password)
    @user = user
    @password = password
  end

  def get(url)
    cur_page = current_page() || Page.new

    # fetch the page
    page = fetch_page(to_absolute_uri(url, cur_page), :get, cur_page)
    add_to_history(page)
    page
  end

  def post(url, query={})
    cur_page = current_page() || Page.new

    request_data = [build_query_string(query)]

    # this is called before the request is sent
    pre_request_hook = proc {|request|
      log.debug("query: #{ query.inspect }")
      request.add_field('Content-Type', 'application/x-www-form-urlencoded')
      request.add_field('Content-Length', request_data[0].size.to_s)
    }

    # fetch the page
    page = fetch_page(to_absolute_uri(url, cur_page), :post, cur_page, pre_request_hook, request_data)
    add_to_history(page) 
    page
  end

  def click(link)
    uri = to_absolute_uri(link.href)
    get(uri)
  end

  def back
    @history.pop
  end

  def submit(form, button=nil)
    query = form.build_query
    button.add_to_query(query) if button

    uri = to_absolute_uri(URI::escape(form.action))
    case form.method.upcase
    when 'POST'
      post_form(uri, form) 
    when 'GET'
      if uri.query.nil?
        get(uri.to_s + "?" + build_query_string(query))
      else
        get(uri.to_s + "&" + build_query_string(query))
      end
    else
      raise 'unsupported method'
    end
  end

  def current_page
    @history.last
  end

  alias page current_page

  private

  def to_absolute_uri(url, cur_page=current_page())
    if url.is_a?(URI)
      uri = url
    else
      uri = URI.parse(url)
    end

    # construct an absolute uri
    if uri.relative?
      if cur_page
        uri = cur_page.uri + url
      else
        raise 'no history. please specify an absolute URL'
      end
    end

    return uri
  end

  def post_form(url, form)
    cur_page = current_page() || Page.new

    request_data = [form.request_data]

    # this is called before the request is sent
    pre_request_hook = proc {|request|
      log.debug("query: #{ request_data.inspect }")
      request.add_field('Content-Type', form.enctype)
      request.add_field('Content-Length', request_data[0].size.to_s)
    }

    # fetch the page
    page = fetch_page(to_absolute_uri(url, cur_page), :post, cur_page, pre_request_hook, request_data)
    add_to_history(page) 
    page
  end

  # uri is an absolute URI
  def fetch_page(uri, method=:get, cur_page=current_page(), pre_request_hook=nil, request_data=[])
    raise "unsupported scheme" unless ['http', 'https'].include?(uri.scheme)

    log.info("#{ method.to_s.upcase }: #{ uri.to_s }")

    page = Page.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)

    if uri.scheme == 'https'
      http.use_ssl = true
      if @ca_file
        http.ca_file = @ca_file
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end
    end


    http.start {

      case method
      when :get
        request = Net::HTTP::Get.new(uri.request_uri)
      when :post
        request = Net::HTTP::Post.new(uri.request_uri)
      else
        raise ArgumentError
      end

      unless @cookie_jar.empty?(uri)
        cookies = @cookie_jar.cookies(uri)
        cookie = cookies.length > 0 ? cookies.join("; ") : nil
        log.debug("use cookie: #{ cookie }")
        request.add_field('Cookie', cookie)
      end

      # Add Referer header to request

      unless cur_page.uri.nil?
        request.add_field('Referer', cur_page.uri.to_s)
      end

      # Add User-Agent header to request

      request.add_field('User-Agent', @user_agent) if @user_agent 

      request.basic_auth(@user, @password) if @user

      # Invoke pre-request-hook (use it to add custom headers or content)

      pre_request_hook.call(request) if pre_request_hook

      # Log specified headers for the request

      request.each_header do |k, v|
        log.debug("request-header: #{ k } => #{ v }")
      end

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

        page.response = response
        page.code = response.code

        response.read_body
        page.body = response.body

        log.info("status: #{ page.code }")

        page.watch_for_set = @watch_for_set

        case page.code
        when "200"
          return page
        when "301", "302"
          log.info("follow redirect to: #{ response.header['Location'] }")
          return fetch_page(to_absolute_uri(response.header['Location'], page), :get, page)
        else
          raise ResponseCodeError.new(page.code), "Unhandled response", caller
        end
      } 
    }
  end

  def build_query_string(hash)
    vals = [] 
    hash.each_pair {|k,v|
      vals <<
      [WEBrick::HTTPUtils.escape_form(k), 
       WEBrick::HTTPUtils.escape_form(v)].join("=")
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
