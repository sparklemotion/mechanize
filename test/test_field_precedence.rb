require 'helper'

class TestFieldPrecedence < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
    @page = @agent.get('http://localhost/tc_field_precedence.html')
  end

  def test_first_field_wins
    form = @page.forms.first
    assert !form.checkboxes.empty?
    assert_equal "1", form.checkboxes.first.value
    assert_equal 'ticky=1&ticky=0', form.submit.parser.at('#query').text
  end
end
