require 'fileutils'

module WWW
  class Mechanize
    # = Synopsis
    # This class encapsulates an HTML page.  If Mechanize finds a content
    # type of 'text/html', this class will be instantiated and returned.
    #
    # == Example
    #  require 'rubygems'
    #  require 'mechanize'
    #
    #  agent = WWW::Mechanize.new
    #  agent.get('http://google.com/').class  #=> WWW::Mechanize::Page
    #
    class Page < File
      attr_accessor :watch_for_set
      attr_finder :frames, :iframes, :links, :forms, :meta, :watches

      # Alias our finders so that we can lazily parse the html
      alias :find_frames   :frames
      alias :find_iframes  :iframes
      alias :find_links    :links
      alias :find_forms    :forms
      alias :find_meta     :meta
      alias :find_watches  :watches
    
      def initialize(uri=nil, response=nil, body=nil, code=nil)
        super(uri, response, body, code)
        @frames       = nil
        @iframes      = nil
        @links        = nil
        @forms        = nil
        @meta         = nil
        @watches      = nil
        @root         = nil
        @title        = nil
      end
    
      # Get the response header
      def header
        @response
      end
    
      # Get the content type
      def content_type
        @response['Content-Type']
      end
    
      # Get a list of Form associated with this page.
      def forms(*args)
        parse_html() unless @forms
        find_forms(*args)
      end
    
      # Get a list of Link associated with this page.
      def links(*args)
        parse_html() unless @links
        find_links(*args)
      end
    
      # Get the root XML parse tree for this page.
      def root
        parse_html() unless @root
        @root
      end
    
      # This method watches out for a particular tag, and will call back to the
      # class specified for the tag in the watch_for_set method.  See the example
      # in this class.
      def watches(*args)
        parse_html() unless @watches 
        find_watches(*args)
      end
    
      # Get a list of Meta links, usually used for refreshing the page.
      def meta(*args)
        parse_html() unless @meta 
        find_meta(*args)
      end

      # Get a list of Frame from the page
      def frames(*args)
        parse_html() unless @frames
        find_frames(*args)
      end

      # Get a list of IFrame from the page
      def iframes(*args)
        parse_html() unless @iframes
        find_iframes(*args)
      end

      # Fetch the title of the page
      def title
        parse_html() unless @title
        @title
      end
    
      def inspect
        "Page: [#{title} '#{uri.to_s}']"
      end

      private
    
      def parse_html
        raise Mechanize::ContentTypeError.new(content_type()) unless
          content_type() =~ /^text\/html/ 
    
        # construct parser and feed with HTML
        parser = HTMLTree::XMLParser.new
        begin
          parser.feed(@body)
        rescue => ex
          if ex.message =~ /attempted adding second root element to document/ and
            # Put the whole document inside a single root element, which I
            # simply name <root>, just to make the parser happy. It's no
            #longer valid HTML, but without a single root element, it's not
            # valid HTML as well.
  
            # TODO: leave a possible doctype definition outside this element.
            parser = HTMLTree::XMLParser.new
            parser.feed("<root>" + @body + "</root>")
          else
            raise
          end
        end
    
        @root = parser.document
    
        @forms    = WWW::Mechanize::List.new
        @links    = WWW::Mechanize::List.new
        @meta     = WWW::Mechanize::List.new
        @frames   = WWW::Mechanize::List.new
        @iframes  = WWW::Mechanize::List.new
        @watches  = {}
    
        @root.each_recursive {|node|
          name = node.name.downcase
    
          case name
          when 'form'
            form = Form.new(node)
            form.action ||= @uri
            @forms << form
          when 'title'
            @title = node.text
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
          when 'iframe'
            @iframes << Frame.new(node)
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
end
