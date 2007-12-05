$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class MechSubclass < WWW::Mechanize
  def set_headers(uri, request, cur_page)
    super(uri, request, cur_page)
    request.add_field('Cookie', 'name=Aaron')
    request
  end
end

class TestSubclass < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = MechSubclass.new
  end

  def test_send_cookie
    page = @agent.get("http://localhost:#{PORT}/send_cookies")
    assert_equal(1, page.links.length)
    assert_not_nil(page.links.find { |l| l.text == "name:Aaron" })
  end
end
