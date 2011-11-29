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

  # suffix of url. dot is a part of suffix, not a delimiter
  #   p page.images[0].url #=> "http://example/test.jpg"
  #   p page.images[0].extname #=> ".jpg"
  # returns "" if url has no suffix
  #   p page.images[1].url #=> "http://example/sampleimage"
  #   p page.images[1].extname #=> ""
  def extname
    # Image#src returns nil when no src attribute
    src ? ::File.extname(src) : nil
  end

  # mime type guessed with image url suffix
  #   p page.images[0].extname #=> ".jpg"
  #   p page.images[0].mime_type #=> "image/jpeg"
  #   page.images_with(:mime_type => /gif|jpeg|png/).each do ...
  # retruns nil if url has no (well-known) suffix
  #   p page.images[1].url #=> "http://example/sampleimage"
  #   p page.images[1].mime_type #=> nil
  def mime_type
    suffix_without_dot = extname ? extname.sub(/\A\./){''}.downcase : nil
    Mechanize::Util::DefaultMimeTypes[suffix_without_dot]
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

  alias :to_s :url

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      q.breakable; q.pp url
      q.breakable; q.pp caption
    }
  end

  alias inspect pretty_inspect # :nodoc:

end

