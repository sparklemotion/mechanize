##
# This class encapsulates links.  It contains the text and the URI for
# 'a' tags parsed out of an HTML page.  If the link contains an image,
# the alt text will be used for that image.
#
# For example, the text for the following links with both be 'Hello World':
#
#   <a href="http://example">Hello World</a>
#   <a href="http://example"><img src="test.jpg" alt="Hello World"></a>

class Mechanize::Page::Link
  attr_reader :node
  attr_reader :href
  attr_reader :attributes
  attr_reader :page
  alias :referer :page

  def initialize(node, mech, page)
    @node       = node
    @attributes = node
    @href       = node['href']
    @mech       = mech
    @page       = page
    @text       = nil
  end

  # Click on this link
  def click
    @mech.click self
  end

  # This method is a shorthand to get link's DOM id.
  # Common usage:
  #   page.link_with(:dom_id => "links_exact_id")
  def dom_id
    node['id']
  end

  # A list of words in the rel attribute, all lower-cased.
  def rel
    @rel ||= (val = attributes['rel']) ? val.downcase.split(' ') : []
  end

  # Test if the rel attribute includes +kind+.
  def rel? kind
    rel.include? kind
  end

  # The text content of this link
  def text
    return @text if @text

    @text = @node.inner_text

    # If there is no text, try to find an image and use it's alt text
    if (@text.nil? or @text.empty?) and imgs = @node.search('img') then
      @text = imgs.map do |e|
        e['alt']
      end.join
    end

    @text
  end

  alias :to_s :text

  def uri
    @href && URI.parse(WEBrick::HTTPUtils.escape(@href))
  end

end

