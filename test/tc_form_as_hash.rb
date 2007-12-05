$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'webrick'
require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestFormHash < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
    @page  = @agent.get('http://localhost/form_multival.html')
  end

  def test_form_hash
    form = @page.forms.name('post_form').first

    assert_not_nil(form)
    field_length = form.fields.length
    assert_nil(form['intarweb'])
    form['intarweb'] = 'Aaron'

    assert_not_nil(form['intarweb'])
    assert_equal(field_length + 1, form.fields.length)
  end

  def test_add_field_via_hash
    form = @page.forms.name('post_form').first

    assert_not_nil(form)
    field_length = form.fields.length
    assert_nil(form['intarweb'])
    form['intarweb'] = 'Aaron'

    assert_not_nil(form['intarweb'])
    assert_equal(field_length + 1, form.fields.length)
  end

  def test_fields_as_hash
    form = @page.forms.name('post_form').first

    assert_not_nil(form)
    assert_equal(2, form.fields.name('first').length)

    form['first'] = 'Aaron'
    assert_equal('Aaron', form['first'])
    assert_equal('Aaron', form.fields.name('first').first.value)
  end

  def test_keys
    @page = @agent.get('http://localhost/empty_form.html')
    form = @page.forms.first

    assert_not_nil(form)
    assert_equal(false, form.has_field?('name'))
    assert_equal(false, form.has_value?('Aaron'))
    assert_equal(0, form.keys.length)
    assert_equal(0, form.values.length)
    form['name'] = 'Aaron'
    assert_equal(true, form.has_field?('name'))
    assert_equal(true, form.has_value?('Aaron'))
    assert_equal(1, form.keys.length)
    assert_equal(['name'], form.keys)
    assert_equal(1, form.values.length)
    assert_equal(['Aaron'], form.values)
  end
end
