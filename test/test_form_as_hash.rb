require 'mechanize/test_case'

class TestFormHash < Mechanize::TestCase
  def setup
    @agent = Mechanize.new
    @page  = @agent.get('http://localhost/form_multival.html')
  end

  def test_form_hash
    form = @page.form_with(:name => 'post_form')

    field_length = form.fields.length
    assert_nil(form['intarweb'])
    form['intarweb'] = 'Aaron'

    assert form['intarweb']
    assert_equal(field_length + 1, form.fields.length)
  end

  def test_add_field_via_hash
    form = @page.form_with(:name => 'post_form')

    field_length = form.fields.length
    assert_nil(form['intarweb'])
    form['intarweb'] = 'Aaron'

    assert form['intarweb']
    assert_equal(field_length + 1, form.fields.length)
  end

  def test_fields_as_hash
    form = @page.form_with(:name => 'post_form')

    assert_equal(2, form.fields_with(:name => 'first').length)

    form['first'] = 'Aaron'
    assert_equal('Aaron', form['first'])
    assert_equal('Aaron', form.field_with(:name => 'first').value)
  end

  def test_keys
    @page = @agent.get('http://localhost/empty_form.html')
    form = @page.forms.first

    assert(!form.has_field?('name'))
    assert(!form.has_value?('Aaron'))
    assert_equal(0, form.keys.length)
    assert_equal(0, form.values.length)

    form['name'] = 'Aaron'

    assert(form.has_field?('name'))
    assert(form.has_value?('Aaron'))
    assert_equal(1, form.keys.length)
    assert_equal(['name'], form.keys)
    assert_equal(1, form.values.length)
    assert_equal(['Aaron'], form.values)
  end
end
