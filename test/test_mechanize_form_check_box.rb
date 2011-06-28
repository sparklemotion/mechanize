require 'helper'

class TestMechanizeFormCheckBox < MiniTest::Unit::TestCase

  def setup
    @agent = Mechanize.new
    @page = @agent.get('http://localhost/tc_checkboxes.html')
  end

  def test_check
    form = @page.forms.first

    form.checkbox_with(:name => 'green').check

    assert(form.checkbox_with(:name => 'green').checked)

    %w{ red blue yellow brown }.each do |color|
      assert_equal(false, form.checkbox_with(:name => color).checked)
    end
  end

  def test_uncheck
    form = @page.forms.first

    checkbox = form.checkbox_with(:name => 'green')

    checkbox.check

    assert form.checkbox_with(:name => 'green').checked

    checkbox.uncheck

    assert !form.checkbox_with(:name => 'green').checked
  end

end

