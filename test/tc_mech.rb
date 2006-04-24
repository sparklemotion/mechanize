$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'webrick'
require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class MechMethodsTest < Test::Unit::TestCase
  include TestMethods

  def test_history
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    0.upto(25) do |i|
      assert_equal(i, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
    page = agent.get("http://localhost:#{@port}/form_test.html")

    assert_equal("http://localhost:#{@port}/form_test.html",
      agent.history.last.uri.to_s)
    assert_equal("http://localhost:#{@port}/",
      agent.history[-2].uri.to_s)
  end

  def test_max_history
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    agent.max_history = 10
    0.upto(10) do |i|
      assert_equal(i, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
    
    0.upto(10) do |i|
      assert_equal(10, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
  end

  def test_back_button
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    0.upto(5) do |i|
      assert_equal(i, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
    page = agent.get("http://localhost:#{@port}/form_test.html")

    assert_equal("http://localhost:#{@port}/form_test.html",
      agent.history.last.uri.to_s)
    assert_equal("http://localhost:#{@port}/",
      agent.history[-2].uri.to_s)

    assert_equal(7, agent.history.size)
    agent.back
    assert_equal(6, agent.history.size)
    assert_equal("http://localhost:#{@port}/",
      agent.history.last.uri.to_s)
  end

  def test_google
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/google.html")
    search = page.forms.find { |f| f.name == "f" }
    assert_not_nil(search)
    assert_not_nil(search.fields.find { |f| f.name == 'q' })
    assert_not_nil(search.fields.find { |f| f.name == 'hl' })
    assert_not_nil(search.fields.find { |f| f.name == 'ie' })
  end

  def test_click
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    agent.user_agent_alias = 'Mac Safari'
    page = agent.get("http://localhost:#{@port}/frame_test.html")
    link = page.links.find { |l| l.text == "Form Test" }
    assert_not_nil(link)
    page = agent.click(link)
    assert_equal("http://localhost:#{@port}/form_test.html",
      agent.history.last.uri.to_s)
  end
end
