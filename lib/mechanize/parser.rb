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
  # or from the URI.  If +full_path+ is true the filename will include the
  # host name and path to the resource, otherwise a filename in the current
  # directory is given.

  def extract_filename full_path = @full_path
    if @uri then
      uri = @uri
      uri += 'index.html' if uri.path.end_with? '/'

      path     = uri.path.split(/\//)
      filename = path.pop || 'index.html'
    else
      path     = []
      filename = 'index.html'
    end

    # Set the filename
    if disposition = @response['content-disposition'] then
      disposition.split(/;\s*/).each do |pair|
        k, v = pair.split(/=/, 2)
        filename = v if k && k.downcase == 'filename'
      end
    elsif @uri then
      filename << '.html' unless filename =~ /\./
      filename << "?#{@uri.query}" if @uri.query
    end

    @filename = if full_path then
                  File.join @uri.host, path, filename
                else
                  filename
                end
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

