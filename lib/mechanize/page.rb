require 'fileutils'
require 'hpricot'

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
      attr_reader :root, :title, :watch_for_set
      attr_reader :frames, :iframes, :links, :forms, :meta, :watches

      def initialize(uri=nil, response=nil, body=nil, code=nil)
        super(uri, response, body, code)
        @watch_for_set = {}

        yield self if block_given?

        raise Mechanize::ContentTypeError.new(response['content-type']) unless
            content_type() =~ /^text\/html/ 
        parse_html if body && response
      end
    
      # Get the response header
      def header
        @response
      end
    
      # Get the content type
      def content_type
        @response['content-type']
      end

      # Search through the page like HPricot
      def search(*args)
        @root.search(*args)
      end

      alias :/ :search
    
      def watch_for_set=(obj)
        @watch_for_set = obj
        parse_html if @body
      end

      private
    
      def parse_html
        # construct parser and feed with HTML
        @root = Hpricot.parse(@body)
    
        @forms    = WWW::Mechanize::List.new
        @links    = WWW::Mechanize::List.new
        @meta     = WWW::Mechanize::List.new
        @frames   = WWW::Mechanize::List.new
        @iframes  = WWW::Mechanize::List.new
        @watches  = {}
    
        # Set the title
        @title = if (@root/'title').text.length > 0
          (@root/'title').text
        end

        # Find all the form tags
        (@root/'form').each do |html_form|
          form = Form.new(html_form)
          form.action ||= @uri
          @forms << form
        end

        # Find all the 'a' tags
        (@root/'a').each do |node|
          @links << Link.new(node)
        end

        # Find all 'meta' tags
        (@root/'meta').each do |node|
          next if node.attributes.nil?
          next unless node.attributes.has_key? 'http-equiv'
          next unless node.attributes.has_key? 'content'
          equiv   = node.attributes['http-equiv']
          content = node.attributes['content']
          if equiv != nil && equiv.downcase == 'refresh'
            if content != nil && content =~ /^\d+\s*;\s*url\s*=\s*(\S+)/i
              node.attributes['href'] = $1
              @meta << Meta.new(node)
            end
          end
        end

        # Find all 'frame' tags
        (@root/'frame').each do |node|
          @frames << Frame.new(node)
        end

        # Find all 'iframe' tags
        (@root/'iframe').each do |node|
          @iframes << Frame.new(node)
        end

        # Find all watch tags
        unless @watch_for_set.nil?
          @watch_for_set.each do |key, klass|
            (@root/key).each do |node|
              @watches[key] ||= []
              @watches[key] << (klass ? klass.new(node) : node)
            end
          end
        end
      end
    end
  end
end
