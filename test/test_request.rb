require 'mechanize/test_case'

class RequestTest < Mechanize::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_uri_is_not_polluted
    uri = URI.parse('http://localhost/')
    @agent.get(uri, {'q' => 'Ruby'})
    assert_equal 'http://localhost/', uri.to_s
  end
end
