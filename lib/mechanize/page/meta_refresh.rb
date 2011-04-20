##
# This class encapsulates a meta element with a refresh http-equiv.  Mechanize
# treats meta refresh elements just like 'a' tags.  MetaRefresh objects will
# contain links, but most likely will have no text.

class Mechanize::Page::MetaRefresh < Mechanize::Page::Link

  attr_reader :delay

  ##
  # Matches the content attribute of a meta refresh element.  After the match:
  #
  #   $1:: delay
  #   $3:: url
  CONTENT_REGEXP = /^\s*(\d+\.?\d*)(;|;\s*url=\s*['"]?(\S*?)['"]?)?\s*$/i

  ##
  # Parses the delay and url from the content attribute of a meta refresh
  # element.  Parse requires the uri of the current page to infer a url when
  # no url is specified.
  #
  # Returns a MetaRefresh instance.
  #
  # Returns nil if the delay and url cannot be parsed.

  def self.parse content, base_uri
    return unless content =~ CONTENT_REGEXP

    delay, refresh_uri = $1, $3

    dest = base_uri
    dest += refresh_uri if refresh_uri

    return delay, dest
  end

  def self.from_node node, page, uri
    http_equiv = node['http-equiv']
    return unless http_equiv and http_equiv.downcase == 'refresh'

    delay, uri = parse node['content'], uri

    return unless delay

    new node, page, delay, uri.to_s
  end

  def initialize node, page, delay, href
    super node, page.mech, page

    @delay = delay.to_i
    @href  = href
  end

end

