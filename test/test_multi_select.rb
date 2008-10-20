require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class MultiSelectTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_select_none
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.field_with(:name => 'list').select_none
    page = @agent.submit(form)
    assert_equal(0, page.links.length)
  end

  def test_select_all
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.field_with(:name => 'list').select_all
    page = @agent.submit(form)
    assert_equal(6, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
    assert_equal(1, page.links_with(:text => 'list:2').length)
    assert_equal(1, page.links_with(:text => 'list:3').length)
    assert_equal(1, page.links_with(:text => 'list:4').length)
    assert_equal(1, page.links_with(:text => 'list:5').length)
    assert_equal(1, page.links_with(:text => 'list:6').length)
  end

  def test_click_all
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.field_with(:name => 'list').options.each { |o| o.click }
    page = @agent.submit(form)
    assert_equal(5, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
    assert_equal(1, page.links_with(:text => 'list:3').length)
    assert_equal(1, page.links_with(:text => 'list:4').length)
    assert_equal(1, page.links_with(:text => 'list:5').length)
    assert_equal(1, page.links_with(:text => 'list:6').length)
  end

  def test_select_default
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    page = @agent.submit(form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:2').length)
  end

  def test_select_one
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.list = 'Aaron'
    assert_equal(['Aaron'], form.list)
    page = @agent.submit(form)
    assert_equal(1, page.links.length)
    assert_equal('list:Aaron', page.links.first.text)
  end

  def test_select_two
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.list = ['1', 'Aaron']
    page = @agent.submit(form)
    assert_equal(2, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
    assert_equal(1, page.links_with(:text => 'list:Aaron').length)
  end

  def test_select_three
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.list = ['1', '2', '3']
    page = @agent.submit(form)
    assert_equal(3, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
    assert_equal(1, page.links_with(:text => 'list:2').length)
    assert_equal(1, page.links_with(:text => 'list:3').length)
  end

  def test_select_three_twice
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.list = ['1', '2', '3']
    form.list = ['1', '2', '3']
    page = @agent.submit(form)
    assert_equal(3, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
    assert_equal(1, page.links_with(:text => 'list:2').length)
    assert_equal(1, page.links_with(:text => 'list:3').length)
  end

  def test_select_with_click
    page = @agent.get("http://localhost/form_multi_select.html")
    form = page.forms.first
    form.list = ['1', 'Aaron']
    form.field_with(:name => 'list').options[3].tick
    assert_equal(['1', 'Aaron', '4'].sort, form.list.sort)
    page = @agent.submit(form)
    assert_equal(3, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
    assert_equal(1, page.links_with(:text => 'list:Aaron').length)
    assert_equal(1, page.links_with(:text => 'list:4').length)
  end
end
