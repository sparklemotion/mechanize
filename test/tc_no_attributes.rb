$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class TestNoAttributes < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_parse_no_attributes
    assert_nothing_raised do
      page = @agent.get("http://localhost:#{PORT}/tc_no_attributes.html")
    end
  end
end
