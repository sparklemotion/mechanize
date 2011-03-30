require "helper"

class TestCustomHeaders < Test::Unit::TestCase

  def setup
    @uri = URI.parse 'http://example'
    @req = Net::HTTP::Get.new @uri.request_uri
    @headers = {}
    @params = { :request => @req, :headers => @headers }

    @ch = Mechanize::Chain.new [Mechanize::Chain::CustomHeaders.new]
  end

  def test_handle
    @headers['Content-Length'] = 300

    @ch.handle @params

    headers = @params[:request].to_hash

    assert_equal [300], headers['content-length']
  end

  def test_handle_etag
    @headers[:etag] = 300

    @ch.handle @params

    headers = @params[:request].to_hash

    assert_equal [300], headers['etag']
  end

  def test_handle_if_modified_since
    @headers[:if_modified_since] = 'some_date'

    @ch.handle @params

    headers = @params[:request].to_hash

    assert_equal %w[some_date], headers['if-modified-since']
  end

  def test_handle_symbol
    @headers[:content_length] = 300

    e = assert_raises ArgumentError do
      @ch.handle @params
    end

    assert_equal 'unknown header symbol content_length', e.message
  end

end
