$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestRadioButtons < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
    @page  = @agent.get("http://localhost:#{PORT}/tc_radiobuttons.html")
  end

  def test_select_one
    form = @page.forms.first
    button = form.radiobuttons.name('color')
    form.radiobuttons.name('color').value('green').tick
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
      b.tick
    end
    form.radiobuttons.name('color').value('green').tick
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
      b.untick
    end
    assert_equal(false, button.value('green').checked)
    assert_equal(false, button.value('red').checked)
    assert_equal(false, button.value('blue').checked)
    assert_equal(false, button.value('yellow').checked)
    assert_equal(false, button.value('brown').checked)
  end
end
