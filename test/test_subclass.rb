require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestSubclass < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_send_cookie
    page = @agent.get(  :url      => "http://localhost/send_cookies",
                        :headers  => {'Cookie' => 'name=Aaron'} )
    assert_equal(1, page.links.length)
    assert_not_nil(page.links.find { |l| l.text == "name:Aaron" })
  end
end
