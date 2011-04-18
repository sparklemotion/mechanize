##
# Raised when Mechanize encounters an error while reading the response body
# from the server.  Contains the response headers and the response body up to
# the error along with the initial error.

class Mechanize::ResponseReadError < Mechanize::Error

  attr_reader :body_io
  attr_reader :error
  attr_reader :response

  ##
  # Creates a new ResponseReadError with the +error+ raised, the +response+
  # and the +body_io+ for content read so far.

  def initialize error, response, body_io
    @error = error
    @response = response
    @body_io = body_io
  end

  def message # :nodoc:
    "#{@error.message} (#{self.class})"
  end

end

