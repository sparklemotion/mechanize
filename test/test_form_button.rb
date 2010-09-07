require "helper"

class TestFormButtons < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_submit_input_tag
    assert_form_contains_button('<input type="submit" value="submit" />')
  end

  def test_button_input_tag
    assert_form_contains_button('<input type="button" value="submit" />')
  end

  def test_submit_button_tag
    assert_form_contains_button('<button type="submit" value="submit"/>')
  end

  def test_button_button_tag
    assert_form_contains_button('<button type="button" value="submit"/>')
  end

  def test_image_button_tag
    assert_form_contains_button('<input type="image" name="submit" src="http://foo.com/image.jpg"/>')
  end
  
  def test_no_name_image_button_tag
    assert_form_contains_button('<input type="image" src="http://foo.com/image.jpg"/>')
  end
  
  def assert_form_contains_button(button)
    page = Mechanize::Page.new(nil, html_response, html(button), 200, @agent)
    assert_equal(1, page.forms.length)
    assert_equal(1, page.forms.first.buttons.length)
  end

  def html(input)
    "<html><body><form>#{input}</form></body></html>"
  end

  def html_response
    { 'content-type' => 'text/html' }
  end
end

