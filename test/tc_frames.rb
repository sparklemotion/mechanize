$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class FramesMechTest < Test::Unit::TestCase
  include TestMethods

  def test_frames
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/frame_test.html")
    assert_equal(3, page.frames.size)
    assert_equal("frame1", page.frames[0].name)
    assert_equal("frame2", page.frames[1].name)
    assert_equal("frame3", page.frames[2].name)
    assert_equal("/google.html", page.frames[0].src)
    assert_equal("/form_test.html", page.frames[1].src)
    assert_equal("/file_upload.html", page.frames[2].src)
  end

  def test_iframes
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/iframe_test.html")
    assert_equal(1, page.iframes.size)
    assert_equal("frame4", page.iframes.first.name)
    assert_equal("/file_upload.html", page.iframes.first.src)
  end
end
