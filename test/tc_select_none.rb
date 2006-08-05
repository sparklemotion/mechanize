$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class SelectNoneTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost:#{PORT}/form_select_none.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_equal("1", @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links.text('list:1').length)
  end
end
