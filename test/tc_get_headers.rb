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

  def test_etag_header
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { :etag => '160604-24bc-9fe2c40'})
    headers = {}
    page.body.split(/[\r\n]+/).each do |header|
      headers.[]=(*header.chomp.split(/\|/))
    end
    assert(headers.has_key?('etag'))
    assert_equal('160604-24bc-9fe2c40', headers['etag'])
  end

  def test_if_modified_since_header
    value = Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { :if_modified_since => value})
    headers = {}
    page.body.split(/[\r\n]+/).each do |header|
      headers.[]=(*header.chomp.split(/\|/))
    end
    assert(headers.has_key?('if-modified-since'))
    assert_equal(value, headers['if-modified-since'])
  end

  def test_string_header
    page = @agent.get(:url => 'http://localhost/http_headers', :headers => { "X-BS-French-Header" => 'Ou est la bibliotheque?'})
    headers = {}
    page.body.split(/[\r\n]+/).each do |header|
      headers.[]=(*header.chomp.split(/\|/))
    end
    assert(headers.has_key?('x-bs-french-header'))
    assert_equal('Ou est la bibliotheque?', headers['x-bs-french-header'])
  end

end
