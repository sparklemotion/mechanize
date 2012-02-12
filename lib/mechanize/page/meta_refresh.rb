##
# This class encapsulates a meta element with a refresh http-equiv.  Mechanize
# treats meta refresh elements just like 'a' tags.  MetaRefresh objects will
# contain links, but most likely will have no text.

class Mechanize::Page::MetaRefresh < Mechanize::Page::Link

  ##
  # Time to wait before next refresh

  attr_reader :delay

  ##
  # This MetaRefresh links did not contain a url= in the content attribute and
  # links to itself.

  attr_reader :link_self

  ##
  # Matches the content attribute of a meta refresh element.  After the match:
  #
  #   $1:: delay
  #   $3:: url

  CONTENT_REGEXP = /^\s*(\d+\.?\d*)(;|;\s*url=\s*['"]?(\S*?)['"]?)?\s*$/i

  ##
  # Regexp of unsafe URI characters that excludes % for Issue #177

  UNSAFE = /[^\-_.!~*'()a-zA-Z\d;\/?:@&%=+$,\[\]]/

  ##
  # Parses the delay and url from the content attribute of a meta refresh
  # element.  Parse requires the uri of the current page to infer a url when
  # no url is specified.
  #
  # Returns an array of [delay, url]. (both in string)
  #
  # Returns nil if the delay and url cannot be parsed.

  def self.parse content, base_uri
    return unless content =~ CONTENT_REGEXP

    link_self = $3.nil? || $3.empty?
    delay = $1
    refresh_uri = $3
    refresh_uri = Mechanize::Util.uri_escape refresh_uri, UNSAFE if refresh_uri

    dest = base_uri
    dest += refresh_uri if refresh_uri

    return delay, dest, link_self
  end

  def self.from_node node, page, uri = nil
    http_equiv = node['http-equiv'] and
      /\ARefresh\z/i =~ http_equiv or return

    delay, uri, link_self = parse node['content'], uri

    return unless delay

    new node, page, delay, uri.to_s, link_self
  end

  def initialize node, page, delay, href, link_self = false
    super node, page.mech, page

    @delay     = delay.include?(?.) ? delay.to_f : delay.to_i
    @href      = href
    @link_self = link_self
  end

end

