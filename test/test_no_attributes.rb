require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestNoAttributes < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_parse_no_attributes
    assert_nothing_raised do
      page = @agent.get('http://localhost/tc_no_attributes.html')
    end
  end
end
