require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestRadioButtons < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page  = @agent.get("http://localhost/tc_radiobuttons.html")
  end

  def test_select_all
    form = @page.forms.first
    form.radiobuttons_with(:name => 'color').each do |b|
      b.check
    end
    form.radiobutton_with(:name => 'color', :value => 'green').check

    assert_equal(true, form.radiobutton_with( :name => 'color',
                                              :value => 'green').checked)

    %w{ red blue yellow brown }.each do |button_value|
      assert_equal(false, form.radiobutton_with(  :name => 'color',
                                                  :value => button_value
                                               ).checked)
    end
  end

  def test_unselect_all
    form = @page.forms.first
    form.radiobuttons_with(:name => 'color').each do |b|
      b.uncheck
    end
    %w{ green red blue yellow brown }.each do |button_value|
      assert_equal(false, form.radiobutton_with(  :name => 'color',
                                                  :value => button_value
                                               ).checked)
    end
  end

  def test_click_one
    form = @page.forms.first
    form.radiobutton_with(:name => 'color', :value => 'green').click

    assert form.radiobutton_with(:name => 'color', :value => 'green').checked

    %w{ red blue yellow brown }.each do |button_value|
      assert_equal(false, form.radiobutton_with(  :name => 'color',
                                                  :value => button_value
                                               ).checked)
    end
  end

  def test_click_twice
    form = @page.forms.first
    form.radiobutton_with(:name => 'color', :value => 'green').click
    assert form.radiobutton_with(:name => 'color', :value => 'green').checked

    form.radiobutton_with(:name => 'color', :value => 'green').click
    %w{ green red blue yellow brown }.each do |button_value|
      assert_equal(false, form.radiobutton_with(  :name => 'color',
                                                  :value => button_value
                                               ).checked)
    end
  end
end
