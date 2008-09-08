require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestSaveFile < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_save_file
    page = @agent.get('http://localhost:2000/form_no_action.html')
    length = page.response['Content-Length']
    page.save_as("test.html")
    file_length = nil
    File.open("test.html", "r") { |f| file_length = f.read.length }
    FileUtils.rm("test.html")
    assert_equal(length.to_i, file_length)
  end

  def test_save_file_default
    page = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/test.html'),
                                    {},
                                    "hello"
                                   )
    page.save
    assert(File.exists?('test.html'))
    page.save
    assert(File.exists?('test.html.1'))
    page.save
    assert(File.exists?('test.html.2'))
    FileUtils.rm("test.html")
    FileUtils.rm("test.html.1")
    FileUtils.rm("test.html.2")
  end

  def test_save_file_default_with_dots
    page = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/../test.html'),
                                    {},
                                    "hello"
                                   )
    page.save
    assert(File.exists?('test.html'))
    page.save
    assert(File.exists?('test.html.1'))
    FileUtils.rm("test.html")
    FileUtils.rm("test.html.1")
  end
end
