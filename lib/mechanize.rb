# Original Code: 
# Copyright (c) 2005 by Michael Neumann (mneumann@ntecs.de) 
#
# New Code:
# Copyright (c) 2006 by Aaron Patterson (aaronp@rubyforge.org) 
#

Version = "0.3.1"

# required due to the missing get_fields method in Ruby 1.8.2
unless RUBY_VERSION > "1.8.2"
  $LOAD_PATH.unshift File.join(File.dirname(__FILE__), "mechanize", "net-overrides")
end
require 'net/http'
require 'net/https'

require 'web/htmltools/xmltree'   # narf
require 'mechanize/parsing'
require 'mechanize/cookie'
require 'uri'
require 'logger'
require 'webrick'
require 'date'

module WWW

class Field
  attr_accessor :name, :value

  def initialize(name, value)
    @name, @value = name, value
  end

  # Returns an array of Field objects
  # TODO: is this correct?
  def self.extract_all_from(root_node)
    fields = []
    root_node.each_recursive {|node|
      if (node.name.downcase == 'input' and 
         %w(text password hidden checkbox radio int).include?(node.attributes['type'].downcase)) or
         %w(textarea option).include?(node.name.downcase)
        fields << Field.new(node.attributes['name'], node.attributes['value']) 
      end
    }
    return fields
  end
end

class FileUpload
  # value is the file-name, not the file-content
  attr_accessor :name
  
  attr_accessor :file_name, :file_data

  def initialize(name, file_name)
    @name, @file_name = name, file_name
    @file_data = nil
  end
end

class Button
  attr_accessor :name, :value

  def initialize(name, value)
    @name, @value = name, value
  end

  def add_to_query(query)
    query[@name] = @value || "" if @name
  end

  # Returns an array of Button objects
  def self.extract_all_from(root_node)
    buttons = []
    root_node.each_recursive {|node|
      if node.name.downcase == 'input' and 
         ['submit'].include?(node.attributes['type'].downcase)
        buttons << Button.new(node.attributes['name'], node.attributes['value'])
      end
    }
    return buttons
  end
end 

class ImageButton < Button
  attr_accessor :x, :y
  
  def add_to_query(query)
    if @name
      query[@name] = @value || ""
      query[@name+".x"] = (@x || "0").to_s
      query[@name+".y"] = (@y || "0").to_s
    end
  end
end

class RadioButton
  attr_accessor :name, :value, :checked

  def initialize(name, value, checked)
    @name, @value, @checked = name, value, checked
  end
end

class CheckBox
  attr_accessor :name, :value, :checked

  def initialize(name, value, checked)
    @name, @value, @checked = name, value, checked
  end
end

class SelectList
  attr_accessor :name, :value, :options

  def initialize(name, node)
    @name = name
    @options = []

    # parse
    node.each_recursive {|n|
      if n.name.downcase == 'option'
        value = n.attributes['value']
        @options << value 
        @value = value if n.attributes['selected']
      end
    }
  end
end

# Class Form does not work in the case there is some invalid (unbalanced) html
# involved, such as: 
#
#   <td>
#     <form>
#   </td>
#   <td>
#     <input .../>
#     </form>
#   </td>
# 
# GlobalForm takes two nodes, the node where the form tag is located
# (form_node), and another node, from which to start looking for form elements
# (elements_node) like buttons and the like. For class Form both fall together
# into one and the same node.

class GlobalForm
  attr_reader :form_node, :elements_node
  attr_accessor :method, :action, :name

  attr_reader :fields, :buttons, :file_uploads, :radiobuttons, :checkboxes

  def initialize(form_node, elements_node)
    @form_node, @elements_node = form_node, elements_node

    @method = (@form_node.attributes['method'] || 'GET').upcase
    @action = @form_node.attributes['action'] 
    @name = @form_node.attributes['name']

    parse
  end

  # In the case of malformed HTML, fields of multiple forms might occure in this forms'
  # field array. If the fields have the same name, posterior fields overwrite former fields.
  # To avoid this, this method rejects all posterior duplicate fields.

  def uniq_fields!
    names_in = {}
    fields.reject! {|f|
      if names_in.include?(f.name)
        true
      else
        names_in[f.name] = true
        false
      end
    }
  end

  def build_query
    query = {}

    fields().each do |f|
      query[f.name] = f.value || ""
    end

    checkboxes().each do |f|
      query[f.name] = f.value || "on" if f.checked
    end

    radio_groups = {}
    radiobuttons().each do |f|
      radio_groups[f.name] ||= []
      radio_groups[f.name] << f 
    end

    # take one radio button from each group
    radio_groups.each_value do |g|
      checked = g.select {|f| f.checked}

      if checked.size == 1
        f = checked.first
        query[f.name] = f.value || ""
      elsif checked.size > 1 
        raise "multiple radiobuttons are checked in the same group!" 
      end
    end

    query
  end

  def parse
    @fields = []
    @buttons = []
    @file_uploads = []
    @radiobuttons = []
    @checkboxes = []

    @elements_node.each_recursive {|node|
      case node.name.downcase
      when 'input'
        case (node.attributes['type'] || 'text').downcase
        when 'text', 'password', 'hidden', 'int'
          @fields << Field.new(node.attributes['name'], node.attributes['value']) 
        when 'radio'
          @radiobuttons << RadioButton.new(node.attributes['name'], node.attributes['value'], node.attributes.has_key?('checked'))
        when 'checkbox'
          @checkboxes << CheckBox.new(node.attributes['name'], node.attributes['value'], node.attributes.has_key?('checked'))
        when 'file'
          @file_uploads << FileUpload.new(node.attributes['name'], node.attributes['value']) 
        when 'submit'
          @buttons << Button.new(node.attributes['name'], node.attributes['value'])
        when 'image'
          @buttons << ImageButton.new(node.attributes['name'], node.attributes['value'])
        end
      when 'textarea'
        @fields << Field.new(node.attributes['name'], node.all_text)
      when 'select'
        @fields << SelectList.new(node.attributes['name'], node)
      end
    }
  end

end

class Form < GlobalForm
  attr_reader :node

  def initialize(node)
    @node = node
    super(@node, @node)
  end
end

class Link
  attr_reader :node
  attr_reader :href
  attr_reader :text

  def initialize(node)
    @node = node
    @href = node.attributes['href'] 
    @text = node.all_text
  end
end

class Meta < Link
end

class Page 
  attr_accessor :uri, :cookies, :response, :body, :code, :watch_for_set

  def initialize(uri=nil, cookies=[], response=nil, body=nil, code=nil)
    @uri, @cookies, @response, @body, @code = uri, cookies, response, body, code
  end

  def header
    @response.header
  end

  def content_type
    header['Content-Type']
  end

  def forms
    parse_html() unless @forms
    @forms
  end

  def links
    parse_html() unless @links
    @links
  end

  def root
    parse_html() unless @root
    @root
  end

  def watches
    parse_html() unless @watches 
    @watches 
  end

  def meta
    parse_html() unless @meta 
    @meta 
  end

  private

  def parse_html
    raise "no html" unless content_type() =~ /^text\/html/ 

    # construct parser and feed with HTML
    parser = HTMLTree::XMLParser.new
    begin
      parser.feed(@body)
    rescue => ex
      if ex.message =~ /attempted adding second root element to document/ and
        # Put the whole document inside a single root element, which I simply name
        # <root>, just to make the parser happy. It's no longer valid HTML, but 
        # without a single root element, it's not valid HTML as well.

        # TODO: leave a possible doctype definition outside this element.
        parser = HTMLTree::XMLParser.new
        parser.feed("<root>" + @body + "</root>")
      else
        raise
      end
    end

    @root = parser.document

    @forms = []
    @links = []
    @meta  = []
    @watches = {}

    @root.each_recursive {|node|
      name = node.name.downcase

      case name
      when 'form'
        @forms << Form.new(node)
      when 'a'
        @links << Link.new(node)
      when 'meta'
        equiv   = node.attributes['http-equiv']
        content = node.attributes['content']
        if equiv != nil && equiv.downcase == 'refresh'
          if content != nil && content =~ /^\d+\s*;\s*url\s*=\s*(\S+)/i
            node.attributes['href'] = $1
            @meta << Meta.new(node)
          end
        end
      else
        if @watch_for_set and @watch_for_set.keys.include?( name )
          @watches[name] = [] unless @watches[name]
          klass = @watch_for_set[name]
          @watches[name] << (klass ? klass.new(node) : node)
        end
      end
    }
  end
end

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
      post(uri, query) 
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

  # uri is an absolute URI
  def fetch_page(uri, method=:get, cur_page=current_page(), pre_request_hook=nil, request_data=[])
    raise "unsupported scheme" unless ['http', 'https'].include?(uri.scheme)

    log.info("#{ method.to_s.upcase }: #{ uri.to_s }")

    page = Page.new(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
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
        when "302"
          log.info("follow redirect to: #{ response.header['Location'] }")
          return fetch_page(to_absolute_uri(response.header['Location'], page), :get, page)
        else
          raise
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
