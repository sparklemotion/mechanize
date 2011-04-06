# = Synopsis
# This class encapsulates an HTML page.  If Mechanize finds a content
# type of 'text/html', this class will be instantiated and returned.
#
# == Example
#  require 'rubygems'
#  require 'mechanize'
#
#  agent = Mechanize.new
#  agent.get('http://google.com/').class  #=> Mechanize::Page
#
class Mechanize::Page < Mechanize::File
  extend Forwardable
  extend Mechanize::ElementMatcher

  attr_accessor :mech

  def initialize(uri=nil, response=nil, body=nil, code=nil, mech=nil)
    @encoding = nil

    method = response.respond_to?(:each_header) ? :each_header : :each
    response.send(method) do |header,v|
      next unless v =~ /charset/i
      encoding = v[/charset=([^; ]+)/i, 1]
      @encoding = encoding unless encoding == 'none'
    end

    # Force the encoding to be 8BIT so we can perform regular expressions.
    # We'll set it to the detected encoding later
    body.force_encoding('ASCII-8BIT') if body && body.respond_to?(:force_encoding)

    @encoding ||= Mechanize::Util.detect_charset(body)

    super(uri, response, body, code)
    @mech           ||= mech

    @encoding = nil if html_body =~ /<meta[^>]*charset[^>]*>/i

    raise Mechanize::ContentTypeError, response['content-type'] unless
      response['content-type'] =~ /^(text\/html)|(application\/xhtml\+xml)/i

    @parser = @links = @forms = @meta = @bases = @frames = @iframes = nil
  end

  def title
    @title ||=
      if doc = parser
        title = if doc.respond_to?(:title)
                  doc.title
                else
                  doc.search('title').inner_text
                end
        if title && !title.empty?
          title
        else
          nil
        end
      end
  end

  def encoding=(encoding)
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

  def parser
    return @parser if @parser

    if body && response
      if mech.html_parser == Nokogiri::HTML
        @parser = mech.html_parser.parse(html_body, nil, @encoding)
      else
        @parser = mech.html_parser.parse(html_body)
      end
    end

    @parser
  end
  alias :root :parser

  # Get the content type
  def content_type
    response['content-type']
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
  # Return a list of all meta tags
  def meta
    @meta ||= search('head > meta').map do |node|
      next unless node['http-equiv'] && node['content']
      (equiv, content) = node['http-equiv'], node['content']
      if equiv && equiv.downcase == 'refresh'
        Meta.parse(content, uri) do |delay, href|
          node['delay'] = delay
          node['href'] = href
          Meta.new(node, @mech, self)
        end
      end
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

  private

  def html_body
    if body
      body.length > 0 ? body : '<html></html>'
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
require 'mechanize/page/meta'

