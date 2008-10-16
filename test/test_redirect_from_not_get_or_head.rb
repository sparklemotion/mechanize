require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestRedirectNotGetOrHead < Test::Unit::TestCase
  include WWW

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_to_s
    page = MechTestHelper.fake_page(@agent)
    error = Mechanize::RedirectNotGetOrHeadError.new(page, :put)
    assert_match(/put/, error.to_s)
  end

  def test_head_redirect_results_in_head_request
    page = @agent.head('http://localhost/redirect')
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal(page.body, "method: HEAD")
  end

  def test_post_redirect_raises_error
    assert_raises(Mechanize::RedirectNotGetOrHeadError) {
      @agent.post('http://localhost/redirect')
    }
  end

  def test_put_redirect_raises_error
    assert_raises(Mechanize::RedirectNotGetOrHeadError) {
      @agent.put('http://localhost/redirect')
    }
  end

  def test_delete_redirect_raises_error
    assert_raises(Mechanize::RedirectNotGetOrHeadError) {
      @agent.delete('http://localhost/redirect')
    }
  end
end
