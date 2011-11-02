require 'mechanize/test_case'

class RequestTest < Mechanize::TestCase
  def test_uri_is_not_polluted
    uri = URI.parse('http://localhost/')
    @mech.get(uri, {'q' => 'Ruby'})
    assert_equal 'http://localhost/', uri.to_s
  end
end
