##
# An image element on an HTML page

class Mechanize::Page::Image
  attr_reader :node
  attr_reader :page
  attr_reader :mech

  def initialize(node, page)
    @node = node
    @page = page
    @mech = page.mech
  end

  def src
    node['src']
  end

  def width
    node['width']
  end

  def height
    node['height']
  end

  def alt
    node['alt']
  end

  def title
    node['title']
  end

  # 'id' attribute of the image
  def dom_id
    node['id']
  end

  # 'class' attribute of the image
  def dom_class
    node['class']
  end

  # "caption" of the image. #title, #alt, or empty string "".
  #   <img src="..." alt="ALT"> ==> "ALT"
  #   <img src="..." title="TITLE"> ==> "TITLE"
  #   <img src="..." alt="ALT" title="TITLE"> ==> "TITLE"
  #   <img src="..." alt="no-popup-ALT" title=""> ==> ""
  #   <img src="..."> ==> ""
  def caption
    title || alt || ''
  end

  alias :text :caption

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

  alias :to_s :url

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      q.breakable; q.pp url
      q.breakable; q.pp caption
    }
  end

  alias inspect pretty_inspect # :nodoc:

end

