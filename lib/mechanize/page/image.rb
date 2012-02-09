##
# An image element on an HTML page

class Mechanize::Page::Image
  attr_reader :node
  attr_accessor :page
  attr_accessor :mech

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

  # url String of self for Page#image_urls
  def url
    if relative?
      if page.bases[0]
        (page.bases[0].href + src).to_s
      else
        (page.uri + src).to_s
      end
    else
      src
    end
  end

  alias :to_s :url

  # get #src with Mechanize#get. returns Mechanize#get result.
  #
  #   agent.page.image_with(:src => /logo/).fetch.save
  #
  # The referer is:
  # #page("parent") ::
  #   all images on http html, relative #src images on https html
  # (no referer)    ::
  #   absolute #src images on https html
  # user specified  ::
  #   img.fetch(nil, my_referer_uri_or_page)

  def fetch(parameters = [], referer = nil, headers = {})
    mech.get(src, parameters, referer || image_referer, headers)
  end

  def image_referer # :nodoc:
    http_page  = page.uri && page.uri.scheme == 'http'
    https_page = page.uri && page.uri.scheme == 'https'

    case
    when http_page               then page
    when https_page && relative? then page
    else
      Mechanize::File.new(nil, { 'content-type' => 'text/plain' }, '', 200)
    end
  end

  def relative? # :nodoc:
    %r{^https?://} !~ src
  end

  # #fetch and File#save(or, Download#save)
  #   page.images_with(:src => /img/).each{|img| img.save}
  #   page.images_with(src: /img/).map(&:save) # Ruby 1.9.x
  def save(path = nil, parameters = [], referer = nil, headers = {})
    fetch(parameters, referer, headers).save(path)
  end

  alias :save_as :save

  # #save self with Mechanize#transact. self is not added to history.
  #   p agent.page.uri.to_s => "http://example/images.html"
  #   agent.page.images[0].download
  #   p agent.page.uri.to_s #=> "http://example/images.html"
  def download(path = nil, parameters = [], referer = nil, headers = {})
    mech.transact{ save(path, parameters, referer, headers) }
  end

  def pretty_print(q) # :nodoc:
    q.object_group(self) {
      q.breakable; q.pp url
      q.breakable; q.pp caption
    }
  end

  alias inspect pretty_inspect # :nodoc:

end

