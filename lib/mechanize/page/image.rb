##
# An image element on an HTML page

class Mechanize::Page::Image
  attr_reader :node
  attr_reader :page

  def initialize(node, page)
    @node = node
    @page = page
  end

  def src
    @node['src']
  end

  def url
    case src
    when %r{^https?://}
      src
    else 
      if page.bases[0]
        (page.bases[0].href + src).to_s
      else
        (page.uri + src).to_s
      end
    end
  end
end

