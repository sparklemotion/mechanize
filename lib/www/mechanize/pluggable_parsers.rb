require 'www/mechanize/file'
require 'www/mechanize/file_saver'
require 'www/mechanize/page'

module WWW
  class Mechanize
    # = Synopsis
    # This class is used to register and maintain pluggable parsers for
    # Mechanize to use.
    #
    # A Pluggable Parser is a parser that Mechanize uses for any particular
    # content type.  Mechanize will ask PluggableParser for the class it
    # should initialize given any content type.  This class allows users to
    # register their own pluggable parsers, or modify existing pluggable
    # parsers.
    #
    # PluggableParser returns a WWW::Mechanize::File object for content types
    # that it does not know how to handle.  WWW::Mechanize::File provides
    # basic functionality for any content type, so it is a good class to
    # extend when building your own parsers.
    # == Example
    # To create your own parser, just create a class that takes four
    # parameters in the constructor.  Here is an example of registering
    # a pluggable parser that handles CSV files:
    #  class CSVParser < WWW::Mechanize::File
    #    attr_reader :csv
    #    def initialize(uri=nil, response=nil, body=nil, code=nil)
    #      super(uri, response, body, code)
    #      @csv = CSV.parse(body)
    #    end
    #  end
    #  agent = WWW::Mechanize.new
    #  agent.pluggable_parser.csv = CSVParser
    #  agent.get('http://example.com/test.csv')  # => CSVParser
    # Now any page that returns the content type of 'text/csv' will initialize
    # a CSVParser and return that object to the caller.
    #
    # To register a pluggable parser for a content type that pluggable parser
    # does not know about, just use the hash syntax:
    #  agent.pluggable_parser['text/something'] = SomeClass
    # 
    # To set the default parser, just use the 'defaut' method:
    #  agent.pluggable_parser.default = SomeClass
    # Now all unknown content types will be instances of SomeClass.
    class PluggableParser
      CONTENT_TYPES = {
        :html => 'text/html',
        :wap  => 'application/vnd.wap.xhtml+xml',
        :xhtml => 'application/xhtml+xml',
        :pdf  => 'application/pdf',
        :csv  => 'text/csv',
        :xml  => 'text/xml',
      }

      attr_accessor :default

      def initialize
        @parsers = { CONTENT_TYPES[:html]   => Page,
                     CONTENT_TYPES[:xhtml]  => Page,
                     CONTENT_TYPES[:wap]    => Page,
        }
        @default = File
      end

      def parser(content_type)
        content_type.nil? ? default : @parsers[content_type] || default
      end

      def register_parser(content_type, klass)
        @parsers[content_type] = klass
      end

      def html=(klass)
        register_parser(CONTENT_TYPES[:html], klass)
        register_parser(CONTENT_TYPES[:xhtml], klass)
      end

      def xhtml=(klass)
        register_parser(CONTENT_TYPES[:xhtml], klass)
      end

      def pdf=(klass)
        register_parser(CONTENT_TYPES[:pdf], klass)
      end

      def csv=(klass)
        register_parser(CONTENT_TYPES[:csv], klass)
      end

      def xml=(klass)
        register_parser(CONTENT_TYPES[:xml], klass)
      end

      def [](content_type)
        @parsers[content_type]
      end

      def []=(content_type, klass)
        @parsers[content_type] = klass
      end
    end
  end
end
