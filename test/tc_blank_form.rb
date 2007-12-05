$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class BlankFormTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_blank_form_query_string
    page = @agent.get('http://localhost/tc_blank_form.html')
    form = page.forms.first
    query = form.build_query
    assert(query.length > 0)
    assert query.all? { |x| x[1] == '' }
  end
end

