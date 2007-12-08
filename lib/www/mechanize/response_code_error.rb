module WWW
  class Mechanize
    # =Synopsis
    # This error is thrown when Mechanize encounters a response code it does
    # not know how to handle.  Currently, this exception will be thrown
    # if Mechanize encounters response codes other than 200, 301, or 302.
    # Any other response code is up to the user to handle.
    class ResponseCodeError < RuntimeError
      attr_reader :response_code
      attr_reader :page
    
      def initialize(page)
        @page          = page
        @response_code = page.code
      end

      def to_s
        "#{response_code} => #{Net::HTTPResponse::CODE_TO_OBJ[response_code]}"
      end

      def inspect; to_s; end
    end
  end
end

