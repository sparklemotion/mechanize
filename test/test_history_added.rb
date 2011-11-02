require 'mechanize/test_case'

class HistoryAddedTest < Mechanize::TestCase
  def test_history_added_gets_called
    onload = 0
    @mech.history_added = lambda { |page|
      onload += 1
    }
    @mech.get('http://localhost/tc_blank_form.html')
    assert_equal(1, onload)
  end
end
