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
  end
end
