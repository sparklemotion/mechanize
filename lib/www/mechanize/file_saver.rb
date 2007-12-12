module WWW
  class Mechanize
    # = Synopsis
    # This is a pluggable parser that automatically saves every file
    # it encounters.  It saves the files as a tree, reflecting the
    # host and file path.
    #
    # == Example to save all PDF's
    #  require 'rubygems'
    #  require 'mechanize'
    #
    #  agent = WWW::Mechanize.new
    #  agent.pluggable_parser.pdf = WWW::Mechanize::FileSaver
    #  agent.get('http://example.com/foo.pdf')
    #
    class FileSaver < File
      attr_reader :filename
  
      def initialize(uri=nil, response=nil, body=nil, code=nil)
        super(uri, response, body, code)
        path = uri.path.empty? ? 'index.html' : uri.path.gsub(/^[\/]*/, '')
        path += 'index.html' if path =~ /\/$/
  
        split_path = path.split(/\//)
        filename = split_path.length > 0 ? split_path.pop : 'index.html'
        joined_path = split_path.join(::File::SEPARATOR)
        path = if joined_path.empty?
          uri.host
        else
          "#{uri.host}#{::File::SEPARATOR}#{joined_path}"
        end
  
        @filename = "#{path}#{::File::SEPARATOR}#{filename}"
        FileUtils.mkdir_p(path)
        save_as(@filename)
      end
    end
  end
end
