# This class encapsulates a Meta tag.  Mechanize treats meta tags just like
# 'a' tags.  Meta objects will contain links, but most likely will have no
# text.

class Mechanize::Page::Meta < Mechanize::Page::Link

  # Matches the content attribute of a meta tag.  After the match:
  #
  #   $1:: delay
  #   $3:: url
  #
  CONTENT_REGEXP = /^\s*(\d+\.?\d*)(;|;\s*url=\s*['"]?(\S*?)['"]?)?\s*$/i

  # Parses the delay and url from the content attribute of a meta tag.  Parse
  # requires the uri of the current page to infer a url when no url is
  # specified.  If a block is given, the parsed delay and url will be passed
  # to it for further processing.
  #
  # Returns nil if the delay and url cannot be parsed.
  #
  #   # <meta http-equiv="refresh" content="5;url=http://example/" />
  #   uri = URI.parse('http://example/')
  #
  #   Meta.parse("5;url=http://example/a", uri)  # => ['5', 'http://example/a']
  #   Meta.parse("5;url=", uri)                  # => ['5', 'http://example/']
  #   Meta.parse("5", uri)                       # => ['5', 'http://example/']
  #   Meta.parse("invalid content", uri)         # => nil
  #
  def self.parse(content, uri)
    return unless content =~ CONTENT_REGEXP

    delay, url = $1, $3

    dest = uri
    dest += url if url
    url = dest.to_s

    yield delay, url if block_given?

    return delay, url
  end

end

