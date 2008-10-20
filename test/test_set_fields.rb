require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestSetFields < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost/form_set_fields.html")
    @form = @page.forms.first
  end

  def test_set_no_fields
    before = {}
    @form.fields.each { |f| before[f.name] = f.value }
    @form.set_fields
    before.each { |k,v| assert_equal(v, @form.send(k)) }
  end

  def test_set_one_field
    @form.set_fields( :gender => 'male' )
    assert_equal('male', @form.gender)
  end

  def test_set_many_fields
    @form.set_fields( :gender       => 'male',
                      :first_name   => 'Aaron',
                      'green[eggs]' => 'Ham'
                    )
    assert_equal('male', @form.gender)
    assert_equal('Aaron', @form.first_name)
    assert_equal('Ham', @form.fields_with(:name => 'green[eggs]').first.value)
  end

  def test_set_multiple_duplicate_fields
    page = @agent.get("http://localhost/form_multival.html")
    form = page.form('post_form')
    form.set_fields( :first => { 0 => 'a', 1 => 'b' } )
    assert_equal('a', form.fields_with(:name => 'first')[0].value)
    assert_equal('b', form.fields_with(:name => 'first')[1].value)
  end

  def test_set_second_field
    @form.set_fields( :first_name => ['Aaron', 1] )
    assert_equal('Aaron', @form.fields_with(:name => 'first_name')[1].value)
  end
end
