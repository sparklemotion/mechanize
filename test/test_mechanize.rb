require 'helper'

class TestMechanize < Test::Unit::TestCase

  def setup
    @agent = Mechanize.new
    @uri = URI.parse 'http://example/'
  end

  def test_connection_for_file
    uri = URI.parse 'file:///nonexistent'
    conn = @agent.connection_for uri

    assert_instance_of Object, conn
    assert_respond_to conn, :request
  end

  def test_connection_for_http
    conn = @agent.connection_for @uri

    assert_equal @agent.http, conn
  end

  def test_http_request_get
    request = @agent.http_request @uri, :get
    
    assert_kind_of Net::HTTP::Get, request
    assert_equal '/', request.path
  end

  def test_http_request_post
    request = @agent.http_request @uri, :post
    
    assert_kind_of Net::HTTP::Post, request
    assert_equal '/', request.path
  end

  def test_resolve_parameters_body
    input_params = { :q => 'hello' }

    uri, params = @agent.resolve_parameters @uri, :post, input_params

    assert_equal 'http://example/', uri.to_s
    assert_equal input_params, params
  end

  def test_resolve_parameters_query
    uri, params = @agent.resolve_parameters @uri, :get, :q => 'hello'

    assert_equal 'http://example/?q=hello', uri.to_s
    assert_nil params
  end

  def test_resolve_parameters_query_append
    input_params = { :q => 'hello' }
    @uri.query = 'a=b'

    uri, params = @agent.resolve_parameters @uri, :get, input_params

    assert_equal 'http://example/?a=b&q=hello', uri.to_s
    assert_nil params
  end

end

