require "helper"

class TestRedirectOk < MiniTest::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_false
    @agent.redirect_ok = false
    page = @agent.get('http://localhost/redirect_ok')
    assert_equal(URI('http://localhost/redirect_ok'), @agent.page.uri)
  end

  def test_true
    @agent.redirect_ok = true
    page = @agent.get('http://localhost/redirect_ok')
    assert_equal(URI('http://localhost/redirect_ok?q=5'), @agent.page.uri)
  end

  def test_permanent
    @agent.redirect_ok = :permanent
    page = @agent.get('http://localhost/redirect_ok')
    assert_equal(URI('http://localhost/redirect_ok?q=3'), @agent.page.uri)
  end
end
