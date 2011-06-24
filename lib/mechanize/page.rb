##
# This class encapsulates an HTML page.  If Mechanize finds a content
# type of 'text/html', this class will be instantiated and returned.
#
# Example:
#
#   require 'mechanize'
#
#   agent = Mechanize.new
#   agent.get('http://google.com/').class # => Mechanize::Page

class Mechanize::Page < Mechanize::File
  extend Forwardable
  extend Mechanize::ElementMatcher

  attr_accessor :mech

  ##
  # Possible encodings for this page based on HTTP headers and meta elements

  attr_reader :encodings

  def initialize(uri=nil, response=nil, body=nil, code=nil, mech=nil)
    raise Mechanize::ContentTypeError, response['content-type'] unless
      response['content-type'] =~ /^(text\/html)|(application\/xhtml\+xml)/i

    @meta_content_type = nil
    @encoding = nil
    @encodings = [nil]
    raise 'no' if mech and not Mechanize === mech
    @mech = mech

    reset

    @encodings << Mechanize::Util.detect_charset(body) if body

    @encodings.concat self.class.response_header_charset(response)

    if body
      # Force the encoding to be 8BIT so we can perform regular expressions.
      # We'll set it to the detected encoding later
      body.force_encoding 'ASCII-8BIT' if body.respond_to? :force_encoding

      @encodings.concat self.class.meta_charset body

      meta_content_type = self.class.meta_content_type body
      @meta_content_type = meta_content_type if meta_content_type
    end

    if mech && mech.default_encoding
      @encodings << mech.default_encoding if mech.default_encoding_fallback
    end

    super(uri, response, body, code)
  end

  def title
    @title ||=
      if doc = parser
        title = doc.search('title').inner_text
        title.empty? ? nil : title
      end
  end

  def response_header_charset
    self.class.response_header_charset(response)
  end

  def meta_charset
    self.class.meta_charset(body)
  end

  def detected_encoding
    Mechanize::Util.detect_charset(body)
  end

  def encoding=(encoding)
    reset

    @encoding = encoding

    if @parser
      parser_encoding = @parser.encoding
      if (parser_encoding && parser_encoding.downcase) != (encoding && encoding.downcase)
        # lazy reinitialize the parser with the new encoding
        @parser = nil
      end
    end

    encoding
  end

  def encoding
    parser.respond_to?(:encoding) ? parser.encoding : nil
  end

  # Return whether parser result has errors related to encoding or not.
  # false indicates just parser has no encoding errors, not encoding is vaild.
  def encoding_error?(parser=nil)
    parser = self.parser unless parser
    return false if parser.errors.empty?
    parser.errors.any? do |error|
      error.message =~ /(indicate\ encoding)|
                        (Invalid\ char)|
                        (input\ conversion\ failed)/x
    end
  end

  def parser
    return @parser if @parser
    return nil unless @body

    if @encoding then
      @parser = @mech.html_parser.parse(html_body, nil, @encoding)
    elsif ! mech.default_encoding_fallback then
      @parser = @mech.html_parser.parse(html_body, nil, @mech.default_encoding)
    else
      @encodings.reverse_each do |encoding|
        @parser = @mech.html_parser.parse(html_body, nil, encoding)

        break unless encoding_error?(@parser)
      end
    end

    @parser
  end

  alias :root :parser

  def reset
    @bases = nil
    @forms = nil
    @frames = nil
    @iframes = nil
    @links = nil
    @labels = nil
    @labels_hash = nil
    @meta_refresh = nil
    @parser = nil
    @title = nil
  end

  # Return the canonical URI for the page if there is a link tag
  # with href="canonical".
  def canonical_uri
    link = at('link[@rel="canonical"][@href]')
    return unless link
    href = link['href']

    URI href
  rescue URI::InvalidURIError
    URI Mechanize::Util.uri_escape href
  end

  # Get the content type
  def content_type
    @meta_content_type || response['content-type']
  end

  # Search through the page like HPricot
  def_delegator :parser, :search, :search
  def_delegator :parser, :/, :/
  def_delegator :parser, :at, :at

  ##
  # :method: form_with(criteria)
  #
  # Find a single form matching +criteria+.
  # Example:
  #   page.form_with(:action => '/post/login.php') do |f|
  #     ...
  #   end

  ##
  # :method: forms_with(criteria)
  #
  # Find all forms form matching +criteria+.
  # Example:
  #   page.forms_with(:action => '/post/login.php').each do |f|
  #     ...
  #   end

  elements_with :form

  ##
  # :method: link_with(criteria)
  #
  # Find a single link matching +criteria+.
  # Example:
  #   page.link_with(:href => /foo/).click

  ##
  # :method: links_with(criteria)
  #
  # Find all links matching +criteria+.
  # Example:
  #   page.links_with(:href => /foo/).each do |link|
  #     puts link.href
  #   end

  elements_with :link

  ##
  # :method: base_with(criteria)
  #
  # Find a single base tag matching +criteria+.
  # Example:
  #   page.base_with(:href => /foo/).click

  ##
  # :method: bases_with(criteria)
  #
  # Find all base tags matching +criteria+.
  # Example:
  #   page.bases_with(:href => /foo/).each do |base|
  #     puts base.href
  #   end

  elements_with :base

  ##
  # :method: frame_with(criteria)
  #
  # Find a single frame tag matching +criteria+.
  # Example:
  #   page.frame_with(:src => /foo/).click

  ##
  # :method: frames_with(criteria)
  #
  # Find all frame tags matching +criteria+.
  # Example:
  #   page.frames_with(:src => /foo/).each do |frame|
  #     p frame.src
  #   end

  elements_with :frame

  ##
  # :method: iframe_with(criteria)
  #
  # Find a single iframe tag matching +criteria+.
  # Example:
  #   page.iframe_with(:src => /foo/).click

  ##
  # :method: iframes_with(criteria)
  #
  # Find all iframe tags matching +criteria+.
  # Example:
  #   page.iframes_with(:src => /foo/).each do |iframe|
  #     p iframe.src
  #   end

  elements_with :iframe

  ##
  # Return a list of all link and area tags
  def links
    @links ||= %w{ a area }.map do |tag|
      search(tag).map do |node|
        Link.new(node, @mech, self)
      end
    end.flatten
  end

  ##
  # Return a list of all form tags
  def forms
    @forms ||= search('form').map do |html_form|
      form = Mechanize::Form.new(html_form, @mech, self)
      form.action ||= @uri.to_s
      form
    end
  end

  ##
  # Return a list of all meta refresh elements

  def meta_refresh
    query = @mech.follow_meta_refresh == :anywhere ? 'meta' : 'head > meta'

    @meta_refresh ||= search(query).map do |node|
      MetaRefresh.from_node node, self, uri
    end.compact
  end

  ##
  # Return a list of all base tags
  def bases
    @bases ||=
      search('base').map { |node| Base.new(node, @mech, self) }
  end

  ##
  # Return a list of all frame tags
  def frames
    @frames ||=
      search('frame').map { |node| Frame.new(node, @mech, self) }
  end

  ##
  # Return a list of all iframe tags
  def iframes
    @iframes ||=
      search('iframe').map { |node| Frame.new(node, @mech, self) }
  end

  ##
  # Return a list of all img tags
  def images
    @images ||=
      search('img').map { |node| Image.new(node, self) }
  end

  def image_urls
    @image_urls ||= images.map(&:url).uniq
  end

  ##
  # Return a list of all label tags
  def labels
    @labels ||=
      search('label').map { |node| Label.new(node, self) }
  end

  def labels_hash
    unless @labels_hash
      hash = {}
      labels.each do |label|
        hash[label.node['for']] = label if label.for
      end
      @labels_hash = hash
    end
    return @labels_hash
  end

  def self.charset content_type
    charset = content_type[/charset=([^; ]+)/i, 1]
    return nil if charset == 'none'
    charset
  end

  def self.response_header_charset(response)
    charsets = []
    response.each do |header, value|
      next unless value =~ /charset/i
      charsets << charset(value)
    end
    charsets
  end

  def self.meta_charset body
    charsets = []

    # HACK use .map
    body.scan(/<meta .*?>/i) do |meta|
      if meta =~ /charset\s*=\s*(["'])?\s*(.+)\s*\1/i then
        charsets << $2
      elsif meta =~ /http-equiv\s*=\s*(["'])?content-type\1/i then
        meta =~ /content=(["'])?(.*?)\1/i

        m_charset = charset $2

        charsets << m_charset if m_charset
      end
    end

    charsets
  end

  def self.meta_content_type body
    # HACK use .map
    body.scan(/<meta .*?>/i) do |meta|
      if meta =~ /http-equiv\s*=\s*(["'])?content-type\1/i then
        meta =~ /content=(["'])?(.*?)\1/i

        return $2
      end
    end

    nil
  end

  private

  def html_body
    if @body
      @body.empty? ? '<html></html>' : @body
    else
      ''
    end
  end

  def self.charset_from_content_type content_type
    charset = content_type[/charset=([^; ]+)/i, 1]
    return nil if charset == 'none'
    charset
  end
end

require 'mechanize/headers'
require 'mechanize/page/image'
require 'mechanize/page/label'
require 'mechanize/page/link'
require 'mechanize/page/base'
require 'mechanize/page/frame'
require 'mechanize/page/meta_refresh'

