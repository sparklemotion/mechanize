module WWW
  class Mechanize
    class Page < WWW::Mechanize::File
      # This class encapsulates a Meta tag.  Mechanize treats meta tags just
      # like 'a' tags.  Meta objects will contain links, but most likely will
      # have no text.
      class Meta < Link
        
        # Matches the content attribute of a meta tag.  After the match:
        #
        #   $1:: delay
        #   $3:: url
        #
        CONTENT_REGEXP = /^\s*(\d+\.?\d*)(;|;\s*url=\s*['"]?(\S*?)['"]?)?\s*$/i
        
        class << self
          # Parses the delay and url from the content attribute of a meta tag.
          # Parse requires the uri of the current page to infer a url when no
          # url is specified.  If a block is given, the parsed delay and url
          # will be passed to it for further processing.
          #
          # Returns nil if the delay and url cannot be parsed.
          #
          #   # <meta http-equiv="refresh" content="5;url=http://example.com/" />
          #   uri = URI.parse('http://current.com/')
          #
          #   Meta.parse("5;url=http://example.com/", uri)  # => ['5', 'http://example.com/']
          #   Meta.parse("5;url=", uri)                     # => ['5', 'http://current.com/']
          #   Meta.parse("5", uri)                          # => ['5', 'http://current.com/']
          #   Meta.parse("invalid content", uri)            # => nil
          #
          def parse(content, uri)
            if content && content =~ CONTENT_REGEXP
              delay, url = $1, $3

              url = case url
              when nil, "" then uri.to_s
              when /^http/i then url
              else "http://#{uri.host}#{url}"
              end

              block_given? ? yield(delay, url) : [delay, url]
            else
              nil
            end
          end
        end
      end
    end
  end
end
