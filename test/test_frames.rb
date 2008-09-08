require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class FramesMechTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_frames
    page = @agent.get("http://localhost/frame_test.html")
    assert_equal(3, page.frames.size)
    assert_equal("frame1", page.frames[0].name)
    assert_equal("frame2", page.frames[1].name)
    assert_equal("frame3", page.frames[2].name)
    assert_equal("/google.html", page.frames[0].src)
    assert_equal("/form_test.html", page.frames[1].src)
    assert_equal("/file_upload.html", page.frames[2].src)
  end

  def test_iframes
    page = @agent.get("http://localhost/iframe_test.html")
    assert_equal(1, page.iframes.size)
    assert_equal("frame4", page.iframes.first.name)
    assert_equal("/file_upload.html", page.iframes.first.src)
  end
end
