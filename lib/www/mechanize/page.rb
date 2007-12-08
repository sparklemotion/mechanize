require 'fileutils'
require 'hpricot'
require 'forwardable'

require 'www/mechanize/page/link'
require 'www/mechanize/page/meta'
require 'www/mechanize/page/base'
require 'www/mechanize/page/frame'

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
    class Page < WWW::Mechanize::File
      extend Forwardable

      attr_reader :parser, :title, :watch_for_set
      attr_reader :frames, :iframes, :links, :forms, :meta, :watches, :bases
      attr_accessor :mech

      alias :root :parser

      def initialize(uri=nil, response=nil, body=nil, code=nil, mech=nil)
        super(uri, response, body, code)
        @watch_for_set  ||= {}
        @mech           ||= mech

        raise Mechanize::ContentTypeError.new(response['content-type']) unless
            content_type() =~ /^text\/html/ 

        # construct parser and feed with HTML
        if body && response
          @parser ||= Hpricot.parse(body)
          parse_html
        end
      end
    
      # Get the content type
      def content_type
        @response['content-type']
      end

      # Search through the page like HPricot
      def_delegator :@parser, :search, :search
      def_delegator :@parser, :/, :/
      def_delegator :@parser, :at, :at

      def watch_for_set=(obj)
        @watch_for_set = obj
        parse_html if @body && @watch_for_set
      end

      # Find a form with +name+.  Form will be yeilded if a block is given.
      def form(name)
        f = forms.name(name).first
        yield f if block_given?
        f
      end
    
      private
    
      def parse_html
        @forms    = WWW::Mechanize::List.new
        @links    = WWW::Mechanize::List.new
        @meta     = WWW::Mechanize::List.new
        @frames   = WWW::Mechanize::List.new
        @iframes  = WWW::Mechanize::List.new
        @bases    = WWW::Mechanize::List.new
        @watches  = {}
    
        # Set the title
        @title = if (@parser/'title').text.length > 0
          (@parser/'title').text
        end

        # Find all 'base' tags
        (@parser/'base').each do |node|
          @bases << Base.new(node, @mech, self)
        end

        # Find all the form tags
        (@parser/'form').each do |html_form|
          form = Form.new(html_form, @mech, self)
          form.action ||= @uri
          @forms << form
        end

        # Find all the 'a' tags
        (@parser/'a').each do |node|
          @links << Link.new(node, @mech, self)
        end

        # Find all the 'area' tags
        (@parser/'area').each do |node|
          @links << Link.new(node, @mech, self)
        end

        # Find all 'meta' tags
        (@parser/'meta').each do |node|
          next unless node['http-equiv']
          next unless node['content']
          equiv   = node['http-equiv']
          content = node['content']
          if equiv != nil && equiv.downcase == 'refresh'
            if content != nil && content =~ /^\d+\s*;\s*url\s*=\s*'?([^\s']+)/i
              node['href'] = $1
              @meta << Meta.new(node, @mech, self)
            end
          end
        end

        # Find all 'frame' tags
        (@parser/'frame').each do |node|
          @frames << Frame.new(node, @mech, self)
        end

        # Find all 'iframe' tags
        (@parser/'iframe').each do |node|
          @iframes << Frame.new(node, @mech, self)
        end

        # Find all watch tags
        unless @watch_for_set.nil?
          @watch_for_set.each do |key, klass|
            (@parser/key).each do |node|
              @watches[key] ||= []
              @watches[key] << (klass ? klass.new(node) : node)
            end
          end
        end
      end
    end
  end
end
