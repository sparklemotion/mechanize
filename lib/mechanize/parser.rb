##
# The parser module provides standard methods for accessing the headers and
# content of a response that are shared across pluggable parsers.

module Mechanize::Parser

  extend Forwardable

  ##
  # The URI this file was retrieved from

  attr_accessor :uri

  ##
  # The Mechanize::Headers for this file

  attr_accessor :response

  alias header response

  ##
  # The HTTP response code

  attr_accessor :code

  ##
  # :method: [](header)
  #
  # Access HTTP +header+ by name

  def_delegator :header, :[], :[]

  ##
  # :method: []=(header, value)
  #
  # Set HTTP +header+ to +value+

  def_delegator :header, :[]=, :[]=

  ##
  # :method: key?(header)
  #
  # Is the named +header+ present?

  def_delegator :header, :key?, :key?

  ##
  # :method: each
  #
  # Enumerate HTTP headers

  def_delegator :header, :each, :each

  ##
  # :method: each
  #
  # Enumerate HTTP headers in capitalized (canonical) form

  def_delegator :header, :canonical_each, :canonical_each

  ##
  # Extracts the filename from a Content-Disposition header in the #response
  # or from the URI.

  def extract_filename
    @filename = 'index.html'

    # Set the filename
    if disposition = @response['content-disposition']
      disposition.split(/;\s*/).each do |pair|
        k, v = pair.split(/=/, 2)
        @filename = v if k && k.downcase == 'filename'
      end
    else
      if @uri then
        @filename = @uri.path.split(/\//).last || 'index.html'
        @filename << ".html" unless @filename =~ /\./
      end
    end

    @filename
  end

  ##
  # Creates a Mechanize::Header from the Net::HTTPResponse +response+.
  #
  # This allows the Net::HTTPResponse to be garbage collected sooner.

  def fill_header response
    @response = Mechanize::Headers.new

    response.each { |k,v|
      @response[k] = v
    } if response

    @response
  end

  ##
  # Finds a free filename based on +filename+, but is not race-free

  def find_free_name filename
    filename = @filename unless filename

    number = 1

    while File.exist? filename do
      filename = "#{@filename}.#{number}"
      number += 1
    end

    filename
  end

end

