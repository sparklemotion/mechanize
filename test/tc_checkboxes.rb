$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestCheckBoxes < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
    @page  = @agent.get("http://localhost:#{PORT}/tc_checkboxes.html")
  end

  def test_select_one
    form = @page.forms.first
    form.checkboxes.name('green').tick
    assert_equal(true,  form.checkboxes.name('green').checked)
    assert_equal(false, form.checkboxes.name('red').checked)
    assert_equal(false, form.checkboxes.name('blue').checked)
    assert_equal(false, form.checkboxes.name('yellow').checked)
    assert_equal(false, form.checkboxes.name('brown').checked)
  end

  def test_select_all
    form = @page.forms.first
    form.checkboxes.each do |b|
      b.tick
    end
    form.checkboxes.each do |b|
      assert_equal(true, b.checked)
    end
  end

  def test_select_none
    form = @page.forms.first
    form.checkboxes.each do |b|
      b.untick
    end
    form.checkboxes.each do |b|
      assert_equal(false, b.checked)
    end
  end

  def test_tick_one
    form = @page.forms.first
    assert_equal(2, form.checkboxes.name('green').length)
    form.checkboxes.name('green')[1].tick
    assert_equal(false,  form.checkboxes.name('green')[0].checked)
    assert_equal(true,  form.checkboxes.name('green')[1].checked)
    page = @agent.submit(form)
    assert_equal(1, page.links.length)
    assert_equal('green:on', page.links.first.text)
  end

  def test_tick_two
    form = @page.forms.first
    assert_equal(2, form.checkboxes.name('green').length)
    form.checkboxes.name('green')[0].tick
    form.checkboxes.name('green')[1].tick
    assert_equal(true,  form.checkboxes.name('green')[0].checked)
    assert_equal(true,  form.checkboxes.name('green')[1].checked)
    page = @agent.submit(form)
    assert_equal(2, page.links.length)
    assert_equal('green:on', page.links.first.text)
    assert_equal('green:on', page.links[1].text)
  end
end
