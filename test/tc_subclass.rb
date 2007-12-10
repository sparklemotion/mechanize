require File.dirname(__FILE__) + "/helper"

class MechSubclass < WWW::Mechanize
  def set_headers(uri, request, cur_page)
    super(uri, request, cur_page)
    request.add_field('Cookie', 'name=Aaron')
    request
  end
end

class TestSubclass < Test::Unit::TestCase
  def setup
    @agent = MechSubclass.new
  end

  def test_send_cookie
    page = @agent.get("http://localhost/send_cookies")
    assert_equal(1, page.links.length)
    assert_not_nil(page.links.find { |l| l.text == "name:Aaron" })
  end
end
