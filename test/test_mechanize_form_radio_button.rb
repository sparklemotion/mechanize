require 'mechanize/test_case'

class TestMechanizeFormRadioButton < Mechanize::TestCase

  def setup
    super

    @page = html_page <<-BODY
<form name="form1" method="post" action="/form_post">
  <label for="blue">Blue</label>
  <input type="radio" name="color" value="blue" id="blue">
  <input type="radio" name="color" value="brown">
  <input type="radio" name="color" value="green">
  <input type="radio" name="color" value="red">
  <input type="radio" name="color" value="yellow">

  <input type="submit" value="Submit">
</form>
    BODY

    @form = @page.forms.first

    @blue   = @form.radiobutton_with :value => 'blue'
    @brown  = @form.radiobutton_with :value => 'brown'
    @green  = @form.radiobutton_with :value => 'green'
    @red    = @form.radiobutton_with :value => 'red'
    @yellow = @form.radiobutton_with :value => 'yellow'
  end
  
  def test_check
    @blue.check

    assert @blue.checked?
    refute @brown.checked?
    refute @green.checked?
    refute @red.checked?
    refute @yellow.checked?
  end

  def test_check_multiple
    @blue.check
    @brown.check

    refute @blue.checked?
    assert @brown.checked?
    refute @green.checked?
    refute @red.checked?
    refute @yellow.checked?
  end

  def test_click
    @blue.click

    assert @blue.checked?

    @blue.click

    refute @blue.checked?
  end

  def test_label
    assert_equal 'Blue', @blue.label.text
  end

  def test_uncheck
    @blue.check

    @blue.uncheck

    refute @blue.checked?
    refute @brown.checked?
    refute @green.checked?
    refute @red.checked?
    refute @yellow.checked?
  end

end

