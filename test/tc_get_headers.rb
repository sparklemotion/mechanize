require File.dirname(__FILE__) + "/helper"

class TestGetHeaders < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_bad_header_symbol
    assert_raises(ArgumentError) do
      @agent.get(:url => "http://localhost/file_upload.html", :headers => { :foobar => "is fubar"})
    end
  end

  def test_host_header
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { :etag => '160604-24bc-9fe2c40'})
    assert_header(page, 'host' => 'localhost')
  end

  def test_etag_header
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { :etag => '160604-24bc-9fe2c40'})
    assert_header(page, 'etag' => '160604-24bc-9fe2c40')
  end

  def test_if_modified_since_header
    value = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { :if_modified_since => value})
    assert_header(page, 'if-modified-since' => value)
  end

  def test_string_header
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { "X-BS-French-Header" => 'Ou est la bibliotheque?'})
    assert_header(page, 'x-bs-french-header' => 'Ou est la bibliotheque?')
  end

  def assert_header(page, header)
    headers = {}
    page.body.split(/[\r\n]+/).each do |page_header|
      headers.[]=(*page_header.chomp.split(/\|/))
    end
    header.each do |key, value|
      assert(headers.has_key?(key))
      assert_equal(value, headers[key])
    end
  end
end
