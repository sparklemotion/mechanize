require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class RequestTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_uri_is_not_polluted
    uri = URI.parse('http://localhost/')
    @agent.get(uri, {'q' => 'Ruby'})
    assert_equal 'http://localhost/', uri.to_s
  end
end
