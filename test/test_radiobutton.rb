require File.dirname(__FILE__) + "/helper"

class TestRadioButtons < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page  = @agent.get("http://localhost/tc_radiobuttons.html")
  end

  def test_select_one
    form = @page.forms.first
    button = form.radiobuttons.name('color')
    form.radiobuttons.name('color').value('green').check
    assert_equal(true, button.value('green').checked)
    assert_equal(false, button.value('red').checked)
    assert_equal(false, button.value('blue').checked)
    assert_equal(false, button.value('yellow').checked)
    assert_equal(false, button.value('brown').checked)
  end

  def test_select_all
    form = @page.forms.first
    button = form.radiobuttons.name('color')
    form.radiobuttons.name('color').each do |b|
      b.check
    end
    form.radiobuttons.name('color').value('green').check
    assert_equal(true, button.value('green').checked)
    assert_equal(false, button.value('red').checked)
    assert_equal(false, button.value('blue').checked)
    assert_equal(false, button.value('yellow').checked)
    assert_equal(false, button.value('brown').checked)
  end

  def test_unselect_all
    form = @page.forms.first
    button = form.radiobuttons.name('color')
    form.radiobuttons.name('color').each do |b|
      b.uncheck
    end
    assert_equal(false, button.value('green').checked)
    assert_equal(false, button.value('red').checked)
    assert_equal(false, button.value('blue').checked)
    assert_equal(false, button.value('yellow').checked)
    assert_equal(false, button.value('brown').checked)
  end

  def test_click_one
    form = @page.forms.first
    button = form.radiobuttons.name('color')
    form.radiobuttons.name('color').value('green').click
    assert_equal(true, button.value('green').checked)
    assert_equal(false, button.value('red').checked)
    assert_equal(false, button.value('blue').checked)
    assert_equal(false, button.value('yellow').checked)
    assert_equal(false, button.value('brown').checked)
  end

  def test_click_twice
    form = @page.forms.first
    button = form.radiobuttons.name('color')
    form.radiobuttons.name('color').value('green').click
    assert_equal(true, button.value('green').checked)
    form.radiobuttons.name('color').value('green').click
    assert_equal(false, button.value('green').checked)
    assert_equal(false, button.value('red').checked)
    assert_equal(false, button.value('blue').checked)
    assert_equal(false, button.value('yellow').checked)
    assert_equal(false, button.value('brown').checked)
  end
end
