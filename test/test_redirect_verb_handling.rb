require "helper"

class TestRedirectNotGetOrHead < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_to_s
    page = MechTestHelper.fake_page(@agent)
    error = Mechanize::RedirectNotGetOrHeadError.new(page, :put)
    assert_match(/put/, error.to_s)
  end

  def test_head_redirect_results_in_head_request
    page = @agent.head('http://localhost/redirect')
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal 'HEAD', page.header['X-Request-Method']
  end

  def test_get_takes_a_verb
    page = @agent.get(:url => 'http://localhost/redirect', :verb => :head)
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal 'HEAD', page.header['X-Request-Method']
  end

  def test_get_redirect_results_in_get_request
    page = @agent.get('http://localhost/redirect')
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_post_redirect_results_in_get_request
    page = @agent.post('http://localhost/redirect')
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_put_redirect_results_in_get_request
    page = @agent.put('http://localhost/redirect', 'foo')
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal 'GET', page.header['X-Request-Method']
  end

  def test_delete_redirect_results_in_get_request
    page = @agent.delete('http://localhost/redirect')
    assert_equal(page.uri.to_s, 'http://localhost/verb')
    assert_equal 'GET', page.header['X-Request-Method']
  end
end
