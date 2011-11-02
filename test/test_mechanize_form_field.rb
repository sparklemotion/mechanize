require 'mechanize/test_case'

class TestMechanizeFormField < Mechanize::TestCase

  def test_field_spaceship
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

