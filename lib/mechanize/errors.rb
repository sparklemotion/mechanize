module WWW
  class Mechanize
    # =Synopsis
    # This class contains an error for when a pluggable parser tries to
    # parse a content type that it does not know how to handle.  For example
    # if WWW::Mechanize::Page were to try to parse a PDF, a ContentTypeError
    # would be thrown.
    class ContentTypeError < RuntimeError
      attr_reader :content_type
    
      def initialize(content_type)
        @content_type = content_type
      end
    end

    # =Synopsis
    # This error is thrown when Mechanize encounters a response code it does
    # not know how to handle.  Currently, this exception will be thrown
    # if Mechanize encounters response codes other than 200, 301, or 302.
    # Any other response code is up to the user to handle.
    class ResponseCodeError < RuntimeError
      attr_reader :response_code
    
      def initialize(response_code)
        @response_code = response_code
      end
    end
  end
end
