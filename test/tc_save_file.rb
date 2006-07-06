$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'
require 'fileutils'

class TestSaveFile < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
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
end
