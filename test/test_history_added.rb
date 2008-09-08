require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class HistoryAddedTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_history_added_gets_called
    onload = 0
    @agent.history_added = lambda { |page|
      onload += 1
    }
    page = @agent.get('http://localhost/tc_blank_form.html')
    assert_equal(1, onload)
  end
end
