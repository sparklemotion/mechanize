require 'mechanize/test_case'

class TestRedirectOk < Mechanize::TestCase

  def test_false
    @mech.redirect_ok = false
    page = @mech.get('http://localhost/redirect_ok')
    assert_equal(URI('http://localhost/redirect_ok'), page.uri)
  end

  def test_true
    @mech.redirect_ok = true
    page = @mech.get('http://localhost/redirect_ok')
    assert_equal(URI('http://localhost/redirect_ok?q=5'), page.uri)
  end

  def test_permanent
    @mech.redirect_ok = :permanent
    page = @mech.get('http://localhost/redirect_ok')
    assert_equal(URI('http://localhost/redirect_ok?q=3'), page.uri)
  end
end
