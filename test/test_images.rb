require "helper"

class ImagesMechTest < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_base
    page = @agent.get("http://google.com/tc_base_images.html")
    assert_equal page.images[0].url, "http://localhost/a.jpg"
    assert_equal page.images[1].url, "http://localhost/b.gif"
  end

  def test_base
    page = @agent.get("http://google.com/tc_images.html")
    assert_equal page.images[0].url, "http://google.com/a.jpg"
    assert_equal page.images[1].url, "http://google.com/b.gif"
  end
end
