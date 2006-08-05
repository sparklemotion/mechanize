$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class SelectAllTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost:#{PORT}/form_select_all.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_equal("6", @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links.text('list:6').length)
  end
end
