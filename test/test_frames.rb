require 'mechanize/test_case'

class FramesMechTest < Mechanize::TestCase
  def setup
    @agent = Mechanize.new
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
    assert_equal("Google", page.frames[0].content.title)
    assert_equal("Page Title", page.frames[1].content.title)
    assert_equal("File Upload Form", page.frames[2].content.title)
  end

  def test_iframes
    page = @agent.get("http://localhost/iframe_test.html")
    assert_equal(1, page.iframes.size)
    assert_equal("frame4", page.iframes.first.name)
    assert_equal("/file_upload.html", page.iframes.first.src)
    assert_equal("File Upload Form", page.iframes.first.content.title)
  end
  
  def test_frame_referer
    page = @agent.get("http://localhost/frame_referer_test.html")    
    assert_equal("http://localhost/frame_referer_test.html", page.frames.first.content.body)
  end
end
