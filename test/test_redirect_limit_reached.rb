require 'mechanize/test_case'

class TestRedirectLimitReached < Mechanize::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_to_s
    page = fake_page @agent
    error = Mechanize::RedirectLimitReachedError.new(page, 10)
    assert_match(/10/, error.to_s)
  end

  def test_get_default_redirects
    assert_raises(Mechanize::RedirectLimitReachedError) {
      begin
        @agent.get('http://localhost/infinite_redirect')
      rescue Mechanize::RedirectLimitReachedError => ex
        assert_equal(@agent.redirection_limit, ex.redirects)
        assert_equal("q=#{@agent.redirection_limit}", ex.page.uri.query)
        raise ex
      end
    }
  end

  def test_get_2_redirects
    @agent.redirection_limit = 2
    assert_raises(Mechanize::RedirectLimitReachedError) {
      begin
        @agent.get('http://localhost/infinite_redirect')
      rescue Mechanize::RedirectLimitReachedError => ex
        assert_equal(2, ex.redirects)
        assert_equal(@agent.redirection_limit, ex.redirects)
        assert_equal("q=#{@agent.redirection_limit}", ex.page.uri.query)
        raise ex
      end
    }
  end
end
