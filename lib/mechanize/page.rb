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

  DEFAULT_RESPONSE = {
    'content-type' => 'text/html',
  }.freeze

  attr_accessor :mech

  ##
  # Possible encodings for this page based on HTTP headers and meta elements

  attr_reader :encodings

  def initialize(uri=nil, response=nil, body=nil, code=nil, mech=nil)
    response ||= DEFAULT_RESPONSE

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

    @encodings << mech.default_encoding if mech and mech.default_encoding

    super uri, response, body, code
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
      if parser_encoding && encoding && parser_encoding.casecmp(encoding) != 0
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
      @parser = @mech.html_parser.parse html_body, nil, @encoding
    elsif mech.force_default_encoding then
      @parser = @mech.html_parser.parse html_body, nil, @mech.default_encoding
    else
      @encodings.reverse_each do |encoding|
        @parser = @mech.html_parser.parse html_body, nil, encoding

        break unless encoding_error? @parser
      end
    end

    @parser
  end

  alias :root :parser

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      q.breakable
      q.group(1, '{url', '}') {q.breakable; q.pp uri }
      q.breakable
      q.group(1, '{meta_refresh', '}') {
        meta_refresh.each { |link| q.breakable; q.pp link }
      }
      q.breakable
      q.group(1, '{title', '}') { q.breakable; q.pp title }
      q.breakable
      q.group(1, '{iframes', '}') {
        iframes.each { |link| q.breakable; q.pp link }
      }
      q.breakable
      q.group(1, '{frames', '}') {
        frames.each { |link| q.breakable; q.pp link }
      }
      q.breakable
      q.group(1, '{links', '}') {
        links.each { |link| q.breakable; q.pp link }
      }
      q.breakable
      q.group(1, '{forms', '}') {
        forms.each { |form| q.breakable; q.pp form }
      }
    }
  end

  alias inspect pretty_inspect # :nodoc:

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

  ##
  # :method: search
  #
  # Search for +paths+ in the page using Nokogiri's #search.  The +paths+ can
  # be XPath or CSS and an optional Hash of namespaces may be appended.
  #
  # See Nokogiri::XML::Node#search for further details.

  def_delegator :parser, :search, :search

  alias / search

  ##
  # :method: at
  #
  # Search through the page for +path+ under +namespace+ using Nokogiri's #at.
  # The +path+ may be either a CSS or XPath expression.
  #
  # See also Nokogiri::XML::Node#at

  def_delegator :parser, :at, :at

  ##
  # :method: form_with
  #
  # :call-seq:
  #   form_with(criteria)
  #
  # Find a single form matching +criteria+.
  # Example:
  #   page.form_with(:action => '/post/login.php') do |f|
  #     ...
  #   end

  ##
  # :method: forms_with
  #
  # :call-seq: forms_with(criteria)
  #
  # Find all forms form matching +criteria+.
  # Example:
  #   page.forms_with(:action => '/post/login.php').each do |f|
  #     ...
  #   end

  elements_with :form

  ##
  # :method: link_with
  #
  # :call-seq: link_with(criteria)
  #
  # Find a single link matching +criteria+.
  # Example:
  #   page.link_with(:href => /foo/).click

  ##
  # :method: links_with
  #
  # :call-seq:
  #   links_with(criteria)
  #
  # Find all links matching +criteria+.
  # Example:
  #   page.links_with(:href => /foo/).each do |link|
  #     puts link.href
  #   end

  elements_with :link

  ##
  # :method: base_with
  #
  # :call-seq: base_with(criteria)
  #
  # Find a single base tag matching +criteria+.
  # Example:
  #   page.base_with(:href => /foo/).click

  ##
  # :method: bases_with
  #
  # :call-seq: bases_with(criteria)
  #
  # Find all base tags matching +criteria+.
  # Example:
  #   page.bases_with(:href => /foo/).each do |base|
  #     puts base.href
  #   end

  elements_with :base

  ##
  # :method: frame_with
  #
  # :call-seq: frame_with(criteria)
  #
  # Find a single frame tag matching +criteria+.
  # Example:
  #   page.frame_with(:src => /foo/).click

  ##
  # :method: frames_with
  #
  # :call-seq: frames_with(criteria)
  #
  # Find all frame tags matching +criteria+.
  # Example:
  #   page.frames_with(:src => /foo/).each do |frame|
  #     p frame.src
  #   end

  elements_with :frame

  ##
  # :method: iframe_with
  #
  # :call-seq: iframe_with(criteria)
  #
  # Find a single iframe tag matching +criteria+.
  # Example:
  #   page.iframe_with(:src => /foo/).click

  ##
  # :method: iframes_with
  #
  # :call-seq: iframes_with(criteria)
  #
  # Find all iframe tags matching +criteria+.
  # Example:
  #   page.iframes_with(:src => /foo/).each do |iframe|
  #     p iframe.src
  #   end

  elements_with :iframe

  ##
  # :method: image_with
  #
  # :call-seq: image_with(criteria)
  #
  # Find a single image matching +criteria+.
  # Example:
  #   page.image_with(:alt => /main/).fetch.save

  ##
  # :method: images_with
  #
  # :call-seq: images_with(criteria)
  #
  # Find all images matching +criteria+.
  # Example:
  #   page.images_with(:src => /jpg\Z/).each do |img|
  #     img.fetch.save
  #   end

  elements_with :image

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
      MetaRefresh.from_node node, self
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

  class << self
    def charset content_type
      charset = content_type[/;(?:\s*,)?\s*charset\s*=\s*([^()<>@,;:\\\"\/\[\]?={}\s]+)/i, 1]
      return nil if charset == 'none'
      charset
    end

    alias charset_from_content_type charset
  end

  def self.response_header_charset response
    charsets = []
    response.each do |header, value|
      next unless header == 'content-type'
      next unless value =~ /charset/i
      charsets << charset(value)
    end
    charsets
  end

  ##
  # Retrieves all charsets from +meta+ tags in +body+

  def self.meta_charset body
    # HACK use .map
    body.scan(/<meta .*?>/i).map do |meta|
      if meta =~ /charset\s*=\s*(["'])?\s*(.+)\s*\1/i then
        $2
      elsif meta =~ /http-equiv\s*=\s*(["'])?content-type\1/i then
        meta =~ /content\s*=\s*(["'])?(.*?)\1/i

        m_charset = charset $2 if $2

        m_charset if m_charset
      end
    end.compact
  end

  ##
  # Retrieves the last <tt>content-type</tt> set by a +meta+ tag in +body+

  def self.meta_content_type body
    body.scan(/<meta .*?>/i).reverse.map do |meta|
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
end

require 'mechanize/headers'
require 'mechanize/page/image'
require 'mechanize/page/label'
require 'mechanize/page/link'
require 'mechanize/page/base'
require 'mechanize/page/frame'
require 'mechanize/page/meta_refresh'

