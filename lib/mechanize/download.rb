##
# Download is a pluggable parser for downloading files without loading them
# into memory first.  You may subclass this class to handle content types you
# do not wish to load into memory first.
#
# See Mechanize::PluggableParser for instructions on using this class.

class Mechanize::Download

  include Mechanize::Parser

  ##
  # The filename for this file based on the content-disposition of the
  # response or the basename of the URL

  attr_accessor :filename

  ##
  # Accessor for the IO-like that contains the body

  attr_reader :body_io

  alias content body_io

  ##
  # Creates a new download retrieved from the given +uri+ and +response+
  # object.  The +body_io+ is an IO-like containing the HTTP response body and
  # +code+ is the HTTP status.

  def initialize uri = nil, response = nil, body_io = nil, code = nil
    @uri      = uri
    @body_io  = body_io
    @code     = code

    @full_path = false unless defined? @full_path

    fill_header response
    extract_filename

    yield self if block_given?
  end

  ##
  # Saves a copy of the body_io to +filename+

  def save filename = nil
    filename = find_free_name filename

    dirname = File.dirname filename
    FileUtils.mkdir_p dirname

    # Ruby 1.8.7 implements StringIO#path, can't use respond_to? :path
    if StringIO === @body_io then
      open filename, 'wb' do |io|
        until @body_io.eof? do
          io.write @body_io.read 16384
        end
      end
    else
      FileUtils.mv @body_io.path, filename
    end
  end

end

