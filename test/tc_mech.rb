$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'webrick'
require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestMechMethods < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
  end

  def test_history
    0.upto(25) do |i|
      assert_equal(i, @agent.history.size)
      page = @agent.get("http://localhost:#{PORT}/")
    end
    page = @agent.get("http://localhost:#{PORT}/form_test.html")

    assert_equal("http://localhost:#{PORT}/form_test.html",
      @agent.history.last.uri.to_s)
    assert_equal("http://localhost:#{PORT}/",
      @agent.history[-2].uri.to_s)

    assert_equal(true, @agent.visited?("http://localhost:#{PORT}/"))
    assert_equal(true, @agent.visited?("/form_test.html"))
    assert_equal(false, @agent.visited?("http://google.com/"))
    assert_equal(true, @agent.visited?(page.links.first))

  end

  def test_max_history
    @agent.max_history = 10
    0.upto(10) do |i|
      assert_equal(i, @agent.history.size)
      page = @agent.get("http://localhost:#{PORT}/")
    end
    
    0.upto(10) do |i|
      assert_equal(10, @agent.history.size)
      page = @agent.get("http://localhost:#{PORT}/")
    end
  end

  def test_back_button
    0.upto(5) do |i|
      assert_equal(i, @agent.history.size)
      page = @agent.get("http://localhost:#{PORT}/")
    end
    page = @agent.get("http://localhost:#{PORT}/form_test.html")

    assert_equal("http://localhost:#{PORT}/form_test.html",
      @agent.history.last.uri.to_s)
    assert_equal("http://localhost:#{PORT}/",
      @agent.history[-2].uri.to_s)

    assert_equal(7, @agent.history.size)
    @agent.back
    assert_equal(6, @agent.history.size)
    assert_equal("http://localhost:#{PORT}/",
      @agent.history.last.uri.to_s)
  end

  def test_google
    page = @agent.get("http://localhost:#{PORT}/google.html")
    search = page.forms.find { |f| f.name == "f" }
    assert_not_nil(search)
    assert_not_nil(search.fields.name('q').first)
    assert_not_nil(search.fields(:name => 'hl').first)
    assert_not_nil(search.fields.find { |f| f.name == 'ie' })
  end

  def test_click
    @agent.user_agent_alias = 'Mac Safari'
    page = @agent.get("http://localhost:#{PORT}/frame_test.html")
    link = page.links.text("Form Test").first
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost:#{PORT}/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_click_hpricot
    page = @agent.get("http://localhost:#{PORT}/frame_test.html")

    link = (page/"a[@class=bar]").first
    assert_not_nil(link)
    page = @agent.click(link)
    assert_equal("http://localhost:#{PORT}/form_test.html",
      @agent.history.last.uri.to_s)
  end

  def test_new_find
    page = @agent.get("http://localhost:#{PORT}/frame_test.html")
    assert_equal(3, page.frames.size)

    find_orig = page.frames.find_all { |f| f.name == 'frame1' }
    find1 = page.frames.with.name('frame1')
    find2 = page.frames.name('frame1')
    find3 = page.frames(:name => 'frame1')

    find_orig.zip(find1, find2, find3).each { |a,b,c,d|
      assert_equal(a, b)
      assert_equal(a, c)
      assert_equal(a, d)
    }
  end

  def test_get_file
    page = @agent.get("http://localhost:#{PORT}/frame_test.html")
    content_length = page.header['Content-Length']
    page_as_string = @agent.get_file("http://localhost:#{PORT}/frame_test.html")
    assert_equal(content_length.to_i, page_as_string.length.to_i)
  end
end
