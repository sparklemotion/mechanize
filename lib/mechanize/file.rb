##
# This is the base class for the Pluggable Parsers.  If Mechanize cannot find
# an appropriate class to use for the content type, this class will be used.
# For example, if you download an image/jpeg, Mechanize will not know how to
# parse it, so this class will be instantiated.
#
# This is a good class to use as the base class for building your own
# pluggable parsers.
#
# == Example
#
#   require 'mechanize'
#
#   agent = Mechanize.new
#   agent.get('http://example.com/foo.jpg').class  #=> Mechanize::File

class Mechanize::File

  extend Forwardable

  ##
  # The URI this file was retrieved from

  attr_accessor :uri

  ##
  # The Net::HTTPResponse for this file

  attr_accessor :response

  ##
  # The HTTP response body, the raw file contents

  attr_accessor :body

  ##
  # The HTTP response code

  attr_accessor :code

  ##
  # The filename for this file based on the content-disposition of the
  # response or the basename of the URL

  attr_accessor :filename

  ##
  # Alias for the HTTP response object

  alias :header :response

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

  alias :content :body

  ##
  # Creates a new file retrieved from the given +uri+ and +response+ object.
  # The +body+ is the HTTP response body and +code+ is the HTTP status.

  def initialize(uri=nil, response=nil, body=nil, code=nil)
    @uri = uri
    @body = body
    @code = code
    @response = Mechanize::Headers.new

    # Copy the headers in to a hash to prevent memory leaks
    if response
      response.each { |k,v|
        @response[k] = v
      }
    end

    @filename = 'index.html'

    # Set the filename
    if disposition = @response['content-disposition']
      disposition.split(/;\s*/).each do |pair|
        k,v = pair.split(/=/, 2)
        @filename = v if k && k.downcase == 'filename'
      end
    else
      if @uri
        @filename = @uri.path.split(/\//).last || 'index.html'
        @filename << ".html" unless @filename =~ /\./
      end
    end

    yield self if block_given?
  end

  ##
  # Use this method to save the content of this object to +filename+

  def save_as(filename = nil)
    if filename.nil?
      filename = @filename
      number = 1
      while(File.exists?(filename))
        filename = "#{@filename}.#{number}"
        number += 1
      end
    end

    open filename, "wb" do |f|
      f.write body
    end
  end

  alias :save :save_as

end

