require 'mechanize/file'
require 'mechanize/file_saver'
require 'mechanize/page'

##
# This class is used to register and maintain pluggable parsers for Mechanize
# to use.
#
# Mechanize allows different parsers for different content types.  Mechanize
# uses PluggableParser to determine which parser to use for any content type.
# To use your own pluggable parser or to change the default pluggable parsers,
# register them with this class.
#
# The default parser for unregistered content types is Mechanize::File.
#
# The module Mechanize::Parser provides basic functionality for any content
# type, so you may use it in custom parsers you write.  For small files you
# wish to perform in-memory operations on, you should subclass
# Mechanize::File.  For large files you should subclass Mechanize::Download as
# the content is only loaded into memory in small chunks.
#
# == Example
#
# To create your own parser, just create a class that takes four parameters in
# the constructor.  Here is an example of registering a pluggable parser that
# handles CSV files:
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
# To register a pluggable parser for a content type that pluggable parser does
# not know about, use the hash syntax:
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
    :html  => 'text/html',
    :wap   => 'application/vnd.wap.xhtml+xml',
    :xhtml => 'application/xhtml+xml',
    :pdf   => 'application/pdf',
    :csv   => 'text/csv',
    :xml   => 'text/xml',
  }

  attr_accessor :default

  def initialize
    @parsers = {
      CONTENT_TYPES[:html]  => Mechanize::Page,
      CONTENT_TYPES[:xhtml] => Mechanize::Page,
      CONTENT_TYPES[:wap]   => Mechanize::Page,
    }

    @default = Mechanize::File
  end

  ##
  # Returns the parser registered for the given +content_type+

  def parser(content_type)
    content_type.nil? ? default : @parsers[content_type] || default
  end

  def register_parser(content_type, klass) # :nodoc:
    @parsers[content_type] = klass
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

  def []=(content_type, klass)
    @parsers[content_type] = klass
  end

end

