module WWW
# = Synopsis
# This class encapsulates a page.
#
# == Example
#  require 'rubygems'
#  require 'mechanize'
#  require 'logger'
#  
#  class Body
#    def initialize(node)
#      puts node.attributes['bgcolor']
#    end
#  end
#  
#  agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
#  agent.user_agent_alias = 'Mac Safari'
#  page = agent.get("http://www.google.com/")
#  page.watch_for_set = { 'body' => Body }
#  
#  body = page.watches
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
  
    # This method watches out for a particular tag, and will call back to the
    # class specified for the tag in the watch_for_set method.  See the example
    # in this class.
    def watches
      parse_html() unless @watches 
      @watches 
    end
  
    def meta
      parse_html() unless @meta 
      @meta 
    end

    def frames
      parse_html() unless @frames
      @frames
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
  
      @forms    = []
      @links    = []
      @meta     = []
      @frames   = []
      @watches  = {}
  
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
        when 'frame'
          @frames << Frame.new(node)
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
end
