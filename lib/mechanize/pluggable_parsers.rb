require 'mechanize/file'
require 'mechanize/file_saver'
require 'mechanize/page'

##
# Mechanize allows different parsers for different content types.  Mechanize
# uses PluggableParser to determine which parser to use for any content type.
# To use your own parser or to change the default parsers, register them with
# this class through Mechanize#pluggable_parser.
#
# The default parser for unregistered content types is Mechanize::File.
#
# The module Mechanize::Parser provides basic functionality for any content
# type, so you may use it in custom parsers you write.  For small files you
# wish to perform in-memory operations on, you should subclass
# Mechanize::File.  For large files you should subclass Mechanize::Download as
# the content is only loaded into memory in small chunks.
#
# When writing your own pluggable parser, be sure to provide a method #body
# that returns a String containing the response body for compatibility with
# Mechanize#get_file.
#
# == Example
#
# To create your own parser, just create a class that takes four parameters in
# the constructor.  Here is an example of registering a parser that handles
# CSV files:
#
#   require 'csv'
#
#   class CSVParser < Mechanize::File
#     attr_reader :csv
#
#     def initialize uri = nil, response = nil, body = nil, code = nil
#       super uri, response, body, code
#       @csv = CSV.parse body
#     end
#   end
#
#   agent = Mechanize.new
#   agent.pluggable_parser.csv = CSVParser
#   agent.get('http://example.com/test.csv')  # => CSVParser
#
# Now any response with a content type of 'text/csv' will initialize a
# CSVParser and return that object to the caller.
#
# To register a parser for a content type that Mechanize does not know about,
# use the hash syntax:
#
#   agent.pluggable_parser['text/something'] = SomeClass
#
# To set the default parser, use #default:
#
#   agent.pluggable_parser.default = Mechanize::Download
#
# Now all unknown content types will be saved to disk and not loaded into
# memory.

class Mechanize::PluggableParser

  CONTENT_TYPES = {
    :html  => ['text/html'],
    :wap   => ['application/vnd.wap.xhtml+xml'],
    :xhtml => ['application/xhtml+xml'],
    :pdf   => ['application/pdf'],
    :csv   => ['text/csv'],
    :xml   => ['text/xml', 'application/xml'],
  }

  attr_accessor :default

  def initialize
    @parsers = {}

    register_parser CONTENT_TYPES[:html], Mechanize::Page
    register_parser CONTENT_TYPES[:xhtml], Mechanize::Page
    register_parser CONTENT_TYPES[:wap], Mechanize::Page
    register_parser 'image', Mechanize::Image

    @default = Mechanize::File
  end

  ##
  # Returns the parser registered for the given +content_type+

  def parser content_type
    return default unless content_type

    parser = @parsers[content_type]

    return parser if parser

    mime_type = MIME::Type.new content_type

    parser = @parsers[mime_type.to_s] ||
             @parsers[mime_type.simplified] ||
             @parsers[mime_type.media_type] ||
             default
  rescue MIME::InvalidContentType
    default
  end

  def register_parser content_types, klass # :nodoc:
    [content_types].flatten.each do |content_type|
      @parsers[content_type] = klass
    end
  end

  ##
  # Registers +klass+ as the parser for text/html and application/xhtml+xml
  # content

  def html=(klass)
    register_parser(CONTENT_TYPES[:html], klass)
    register_parser(CONTENT_TYPES[:xhtml], klass)
  end

  ##
  # Registers +klass+ as the parser for application/xhtml+xml content

  def xhtml=(klass)
    register_parser(CONTENT_TYPES[:xhtml], klass)
  end

  ##
  # Registers +klass+ as the parser for application/pdf content

  def pdf=(klass)
    register_parser(CONTENT_TYPES[:pdf], klass)
  end

  ##
  # Registers +klass+ as the parser for text/csv content

  def csv=(klass)
    register_parser(CONTENT_TYPES[:csv], klass)
  end

  ##
  # Registers +klass+ as the parser for text/xml content

  def xml=(klass)
    register_parser(CONTENT_TYPES[:xml], klass)
  end

  ##
  # Retrieves the parser for +content_type+ content

  def [](content_type)
    @parsers[content_type]
  end

  ##
  # Sets the parser for +content_type+ content to +klass+
  #
  # The +content_type+ may either be a full MIME type a simplified MIME type
  # ('text/x-csv' simplifies to 'text/csv') or a media type like 'image'.

  def []= content_type, klass
    register_parser content_type, klass
  end

end

