require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestCheckBoxes < Test::Unit::TestCase
  def test_field
    f = WWW::Mechanize::Form::Field.new('a&amp;b', 'a&amp;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)

    f = WWW::Mechanize::Form::Field.new('a&b', 'a&b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)

    f = WWW::Mechanize::Form::Field.new('a&#38;b', 'a&#38;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)
  end

  def test_file_upload
    f = WWW::Mechanize::Form::FileUpload.new('a&amp;b', 'a&amp;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.file_name)

    f = WWW::Mechanize::Form::FileUpload.new('a&b', 'a&b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.file_name)
  end

  def test_image_button
    f = WWW::Mechanize::Form::ImageButton.new('a&amp;b', 'a&amp;b')
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)
  end

  def test_radio_button
    f = WWW::Mechanize::Form::RadioButton.new('a&amp;b', 'a&amp;b', nil, nil)
    assert_equal('a&b', f.name)
    assert_equal('a&b', f.value)
  end
end
