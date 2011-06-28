require "helper"

class TestCheckBoxes < MiniTest::Unit::TestCase
  def test_field
    f = Mechanize::Form::Field.new({'name' => 'a&amp;b'}, 'a&amp;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)

    f = Mechanize::Form::Field.new({'name' => 'a&b'}, 'a&b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)

    f = Mechanize::Form::Field.new({'name' => 'a&#38;b'}, 'a&#38;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)
  end

  def test_file_upload
    f = Mechanize::Form::FileUpload.new(fake_node, 'a&amp;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.file_name)

    f = Mechanize::Form::FileUpload.new(fake_node, 'a&b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.file_name)
  end

  def test_image_button
    f = Mechanize::Form::ImageButton.new({'name' => 'a&amp;b'}, 'a&amp;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)
  end

  def test_radio_button
    f = Mechanize::Form::RadioButton.new(fake_node, nil)
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)
  end

  def fake_node
    {
      'name'  => 'a&amp;b',
      'value' => 'a&amp;b'
    }
  end
end
