require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class SelectTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost/form_select.html")
    @form = @page.forms.first
  end

  def test_select_none
    @form.fields_with(:name => 'list').first.select_none
    assert_equal('1', @form.list)
  end

  def test_select_all
    @form.fields_with(:name => 'list').first.select_all
    assert_equal('6', @form.list)
  end

  def test_correct_class
    assert_instance_of(WWW::Mechanize::Form::SelectList,
      @form.field_with(:name => 'list'))
  end

  def test_click_all
    @form.field_with(:name => 'list').options.each { |o| o.click }
    option_list = @form.field_with(:name => 'list').options
    assert_not_nil(option_list)
    assert_equal(6, option_list.length)
    assert_equal(option_list.last.value, @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => "list:#{option_list.last}").length)
  end

  def test_select_default
    assert_equal("2", @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:2').length)
  end

  def test_select_one
    @form.list = 'Aaron'
    assert_equal('Aaron', @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal('list:Aaron', page.links.first.text)
  end

  def test_select_two
    @form.list = ['1', 'Aaron']
    assert_equal('1', @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
  end

  def test_select_three
    @form.list = ['1', '2', '3']
    assert_equal('1', @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
  end

  def test_select_three_twice
    @form.list = ['1', '2', '3']
    @form.list = ['1', '2', '3']
    assert_equal('1', @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
  end

  def test_select_with_empty_value
    list = @form.field_with(:name => 'list')
    list.options.last.instance_variable_set(:@value, '')
    list.options.last.tick
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:').length)
  end

  def test_select_with_click
    @form.list = ['1', 'Aaron']
    @form.field_with(:name => 'list').options[3].tick
    assert_equal('4', @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:4').length)
  end

  def test_click_twice
    list = @form.field_with(:name => 'list')
    list.options[0].click
    assert_equal('1', @form.list)
    list.options[1].click
    assert_equal('2', @form.list)
    list.options.last.click
    assert_equal('6', @form.list)
    assert_equal(1, list.selected_options.length)
    list.select_all
    assert_equal(1, list.selected_options.length)
  end
end
