##
# Download is a pluggable parser for downloading files without loading them
# into memory first.  You may subclass this class to handle content types you
# do not wish to load into memory first.
#
# See Mechanize::PluggableParser for instructions on using this class.

class Mechanize::Download < Mechanize::File

  ##
  # Accessor for the IO-like that contains the body

  attr_reader :body_io

  # This method returns an IO-like object, not a String like
  # Mechanize::File and Mechanize::Page do.
  alias content body_io

  # Returns a whole content body.  Use save() instead if you just want
  # to download the content into a file.
  def body
    @body_io.read.tap {
      @body_io.rewind
    }
  end

  ##
  # Creates a new download retrieved from the given +uri+ and +response+
  # object.  The +body_io+ is an IO-like containing the HTTP response body and
  # +code+ is the HTTP status.

  def initialize uri = nil, response = nil, body_io = nil, code = nil
    super uri, response, nil, code
    @body_io  = body_io
  end

  ##
  # Saves a copy of the body_io to +filename+

  def save filename = nil
    filename = find_free_name filename

    dirname = File.dirname filename
    FileUtils.mkdir_p dirname

    open filename, 'wb' do |io|
      until @body_io.eof? do
        io.write @body_io.read 16384
      end
    end
  end

end

