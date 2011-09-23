# -*- coding: utf-8 -*-
require 'helper'
require 'cgi'

# tests for Page encoding and charset and parsing

class TestMechanizePageEncoding < MiniTest::Unit::TestCase

  MECH_ASCII_ENCODING = Mechanize::Util::NEW_RUBY_ENCODING ? 'US-ASCII' : 'ISO-8859-1'

  def setup
    @agent = Mechanize.new
    @uri = URI('http://localhost/')
    @response_headers = { 'content-type' => 'text/html' }
    @body = '<title>hi</title>'
  end

  def util_page body = @body, headers = @response_headers
    body.force_encoding Encoding::BINARY if body.respond_to? :force_encoding
    Mechanize::Page.new @uri, headers, body, 200, @agent
  end

  def test_page_charset
    charset = Mechanize::Page.charset 'text/html;charset=vAlue'
    assert_equal 'vAlue', charset
  end

  def test_page_charset_upcase
    charset = Mechanize::Page.charset 'TEXT/HTML;CHARSET=UTF-8'
    assert_equal 'UTF-8', charset
  end

  def test_page_semicolon
    charset = Mechanize::Page.charset 'text/html;charset=UTF-8;'
    assert_equal 'UTF-8', charset
  end

  def test_page_charset_no_chaset_token
    charset = Mechanize::Page.charset 'text/html'
    assert_nil charset
  end

  def test_page_charset_returns_nil_when_charset_says_none
    charset = Mechanize::Page.charset 'text/html;charset=none'

    assert_nil charset
  end

  def test_page_charset_multiple
    charset = Mechanize::Page.charset 'text/html;charset=111;charset=222'

    assert_equal '111', charset
  end

  def test_page_response_header_charset
    headers = {'content-type' => 'text/html;charset=HEADER'}
    charsets = Mechanize::Page.response_header_charset(headers)

    assert_equal ['HEADER'], charsets
  end

  def test_page_response_header_charset_no_token
    headers = {'content-type' => 'text/html'}
    charsets = Mechanize::Page.response_header_charset(headers)

    assert_equal [], charsets

    headers = {'X-My-Header' => 'hello'}
    charsets = Mechanize::Page.response_header_charset(headers)

    assert_equal [], charsets
  end

  def test_response_header_charset
    page = util_page nil, {'content-type' => 'text/html;charset=HEADER'}

    assert_equal ['HEADER'], page.response_header_charset
  end

  def test_page_meta_charset
    body = '<meta http-equiv="content-type" content="text/html;charset=META">'
    charsets = Mechanize::Page.meta_charset(body)

    assert_equal ['META'], charsets
  end

  def test_page_meta_charset_is_empty_when_no_charset_meta
    body = '<meta http-equiv="refresh" content="5; url=index.html">'
    charsets = Mechanize::Page.meta_charset(body)
    assert_equal [], charsets
  end

  # Test to fix issue: https://github.com/tenderlove/mechanize/issues/143
  def test_page_meta_charset_handles_whitespace
    body = '<meta http-equiv = "Content-Type" content = "text/html; charset=iso-8859-1">'
    charsets = Mechanize::Page.meta_charset(body)
    assert_equal ["iso-8859-1"], charsets
  end

  def test_meta_charset
    body = '<meta http-equiv="content-type" content="text/html;charset=META">'
    page = util_page body

    assert_equal ['META'], page.meta_charset
  end

  def test_detected_encoding
    page = util_page

    assert_equal MECH_ASCII_ENCODING, page.detected_encoding
  end

  def test_encodings
    response = {'content-type' => 'text/html;charset=HEADER'}
    body = '<meta http-equiv="content-type" content="text/html;charset=META">'
    @agent.default_encoding = 'DEFAULT'
    page = util_page body, response

    assert_equal true, page.encodings.include?('HEADER')
    assert_equal true, page.encodings.include?('META')
    assert_equal true, page.encodings.include?(MECH_ASCII_ENCODING)
    assert_equal true, page.encodings.include?('DEFAULT')
  end

  def test_parser_with_default_encoding
    # pre test
    assert_equal false, util_page.encodings.include?('Windows-1252')

    @agent.default_encoding = 'Windows-1252'
    page = util_page

    assert_equal true, page.encodings.include?('Windows-1252')
  end

  def test_parser_force_default_encoding
    @agent.default_encoding = 'Windows-1252'
    @agent.force_default_encoding = true
    page = util_page

    assert page.encodings.include? 'Windows-1252'
  end

  def test_parser_encoding_equals_overwrites_force_default_encoding
    @agent.default_encoding = 'Windows-1252'
    @agent.force_default_encoding = true
    page = util_page

    assert_equal 'Windows-1252', page.encoding

    page.encoding = 'ISO-8859-2'

    assert_equal 'ISO-8859-2', page.encoding
  end
end
