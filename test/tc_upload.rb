$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class UploadMechTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_form_enctype
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    assert_equal('multipart/form-data', page.forms[0].enctype)

    form = page.forms.first
    form.file_uploads.first.file_name = "README"
    form.file_uploads.first.mime_type = "text/plain"
    form.file_uploads.first.file_data = "Hello World\n\n"

    page = @agent.submit(form)

    assert_match(
      "Content-Disposition: form-data; name=\"userfile1\"; filename=\"README\"",
      page.body
    )
    assert_match(
      "Content-Disposition: form-data; name=\"name\"",
      page.body
    )
    assert_match('Content-Type: text/plain', page.body)
    assert_match('Hello World', page.body)
    assert_match('foo[aaron]', page.body)
  end

  def test_form_multipart
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "README"
    form.file_uploads.first.mime_type = "text/plain"
    form.file_uploads.first.file_data = "Hello World\n\n"

    page = @agent.submit(form)

    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"README\"",
      page.body
    )
  end

  def test_form_read_file
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "README"

    page = @agent.submit(form)

    contents = File.open("README", 'rb') { |f| f.read }
    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"README\"",
      page.body
    )
    assert_match(contents, page.body)
  end

  def test_form_io_obj
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "README"
    form.file_uploads.first.file_data = File.open("README", 'rb')

    page = @agent.submit(form)

    contents = File.open("README", 'rb') { |f| f.read }
    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"README\"",
      page.body
    )
    assert_match(contents, page.body)
  end

  def test_submit_no_file
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    form = page.forms.first
    form.fields.name('name').value = 'Aaron'
    page = @agent.submit(form)
    assert_match('Aaron', page.body)
    assert_match(
      "Content-Disposition: form-data; name=\"userfile1\"; filename=\"\"",
      page.body
    )
  end

  def test_no_value
    page = @agent.get("http://localhost:#{PORT}/file_upload.html")
    form = page.form('value_test')
    assert_nil(form.file_uploads.first.value)
    assert_nil(form.file_uploads.first.file_name)
  end
end
