$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestKeepAlive < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_keep_alive
    page = @agent.get('http://localhost/http_headers')
    headers = {}
    page.body.split(/[\r\n]+/).each do |header|
      headers.[]=(*header.chomp.split(/\|/))
    end
    assert(headers.has_key?('connection'))
    assert_equal('keep-alive', headers['connection'])
    assert(headers.has_key?('keep-alive'))
    assert_equal('300', headers['keep-alive'])
  end

  def test_close_connection
    @agent.keep_alive = false
    page = @agent.get('http://localhost/http_headers')
    headers = {}
    page.body.split(/[\r\n]+/).each do |header|
      headers.[]=(*header.chomp.split(/\|/))
    end
    assert(headers.has_key?('connection'))
    assert_equal('close', headers['connection'])
    assert(!headers.has_key?('keep-alive'))
  end
end
