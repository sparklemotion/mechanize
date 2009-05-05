module WWW
  class Mechanize
    # = Synopsis
    # This is the default (and base) class for the Pluggable Parsers.  If
    # Mechanize cannot find an appropriate class to use for the content type,
    # this class will be used.  For example, if you download a JPG, Mechanize
    # will not know how to parse it, so this class will be instantiated.
    #
    # This is a good class to use as the base class for building your own
    # pluggable parsers.
    #
    # == Example
    #  require 'rubygems'
    #  require 'mechanize'
    #
    #  agent = WWW::Mechanize.new
    #  agent.get('http://example.com/foo.jpg').class  #=> WWW::Mechanize::File
    #
    class File
      attr_accessor :uri, :response, :body, :code, :filename
      alias :header :response

      alias :content :body

      def initialize(uri=nil, response=nil, body=nil, code=nil)
        @uri, @body, @code = uri, body, code
        @response = Headers.new

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

      # Use this method to save the content of this object to filename
      def save_as(filename = nil)
        if filename.nil?
          filename = @filename
          number = 1
          while(::File.exists?(filename))
            filename = "#{@filename}.#{number}"
            number += 1
          end
        end

        ::File::open(filename, "wb") { |f|
          f.write body
        }
      end

      alias :save :save_as
    end
  end
end
