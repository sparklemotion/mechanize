$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class UploadMechTest < Test::Unit::TestCase
  include TestMethods

  def test_form_enctype
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/file_upload.html")
    assert_equal('multipart/form-data', page.forms[0].enctype)

    form = page.forms.first
    form.file_uploads.first.file_name = "README"
    form.file_uploads.first.mime_type = "text/plain"
    form.file_uploads.first.file_data = "Hello World\n\n"

    page = agent.submit(form)

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
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/file_upload.html")
    assert_equal('multipart/form-data', page.forms[1].enctype)

    form = page.forms[1]
    form.file_uploads.first.file_name = "README"
    form.file_uploads.first.mime_type = "text/plain"
    form.file_uploads.first.file_data = "Hello World\n\n"

    page = agent.submit(form)

    assert_match(
      "Content-Disposition: form-data; name=\"green[eggs]\"; filename=\"README\"",
      page.body
    )
  end
end
