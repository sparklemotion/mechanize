require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestCheckBoxes < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get('http://localhost/tc_checkboxes.html')
  end

  def test_select_one
    form = @page.forms.first
    form.checkboxes.name('green').check
    assert_equal(true,  form.checkboxes.name('green').checked)
    assert_equal(false, form.checkboxes.name('red').checked)
    assert_equal(false, form.checkboxes.name('blue').checked)
    assert_equal(false, form.checkboxes.name('yellow').checked)
    assert_equal(false, form.checkboxes.name('brown').checked)
  end

  def test_select_all
    form = @page.forms.first
    form.checkboxes.each do |b|
      b.check
    end
    form.checkboxes.each do |b|
      assert_equal(true, b.checked)
    end
  end

  def test_select_none
    form = @page.forms.first
    form.checkboxes.each do |b|
      b.uncheck
    end
    form.checkboxes.each do |b|
      assert_equal(false, b.checked)
    end
  end

  def test_check_one
    form = @page.forms.first
    assert_equal(2, form.checkboxes.name('green').length)
    form.checkboxes.name('green')[1].check
    assert_equal(false,  form.checkboxes.name('green')[0].checked)
    assert_equal(true,  form.checkboxes.name('green')[1].checked)
    page = @agent.submit(form)
    assert_equal(1, page.links.length)
    assert_equal('green:on', page.links.first.text)
  end

  def test_check_two
    form = @page.forms.first
    assert_equal(2, form.checkboxes.name('green').length)
    form.checkboxes.name('green')[0].check
    form.checkboxes.name('green')[1].check
    assert_equal(true,  form.checkboxes.name('green')[0].checked)
    assert_equal(true,  form.checkboxes.name('green')[1].checked)
    page = @agent.submit(form)
    assert_equal(2, page.links.length)
    assert_equal('green:on', page.links.first.text)
    assert_equal('green:on', page.links[1].text)
  end
end
