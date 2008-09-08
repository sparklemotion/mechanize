require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestTextArea < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page  = @agent.get("http://localhost/tc_textarea.html")
  end

  def test_empty_text_area
    form = @page.forms.name('form1').first
    assert_equal('', form.fields.name('text1').value)
    form.text1 = 'Hello World'
    assert_equal('Hello World', form.fields.name('text1').value)
    page = @agent.submit(form)
    assert_equal(1, page.links.length)
    assert_equal('text1:Hello World', page.links[0].text)
  end

  def test_non_empty_textfield
    form = @page.forms.name('form2').first
    assert_equal('sample text', form.fields.name('text1').value)
    page = @agent.submit(form)
    assert_equal(1, page.links.length)
    assert_equal('text1:sample text', page.links[0].text)
  end

  def test_multi_textfield
    form = @page.forms.name('form3').first
    assert_equal(2, form.fields.name('text1').length)
    assert_equal('', form.fields.name('text1')[0].value)
    assert_equal('sample text', form.fields.name('text1')[1].value)
    form.text1 = 'Hello World'
    assert_equal('Hello World', form.fields.name('text1')[0].value)
    assert_equal('sample text', form.fields.name('text1')[1].value)
    page = @agent.submit(form)
    assert_equal(2, page.links.length)
    link = page.links.text('text1:sample text')
    assert_not_nil(link)
    assert_equal(1, link.length)

    link = page.links.text('text1:Hello World')
    assert_not_nil(link)
    assert_equal(1, link.length)
  end
end
