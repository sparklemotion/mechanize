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

  def test_field_sort
    doc = Nokogiri::HTML::Document.new
    node = doc.create_element('input')
    node['name'] = 'foo'
    node['value'] = 'bar'

    a = Mechanize::Form::Field.new(node)
    b = Mechanize::Form::Field.new({'name' => 'foo'}, 'bar')
    c = Mechanize::Form::Field.new({'name' => 'foo'}, 'bar')

    assert_equal [a, b], [a, b].sort
    assert_equal [a, b], [b, a].sort
    assert_equal [b, c].sort, [b, c].sort
  end
end
