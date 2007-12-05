$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class FollowMetaTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_follow_meta
    page = @agent.get('http://localhost/tc_follow_meta.html')
    assert_equal('http://localhost/tc_follow_meta.html', page.uri.to_s)
    assert_equal(1, page.meta.length)

    @agent.follow_meta_refresh = true
    page = @agent.get('http://localhost/tc_follow_meta.html')
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal(3, @agent.history.length)
  end

  def test_follow_meta_on_302
    @agent.follow_meta_refresh = true
    assert_nothing_raised {
      @agent.get("http://localhost/response_code?code=302&ct=test/xml")
    }
  end
end
