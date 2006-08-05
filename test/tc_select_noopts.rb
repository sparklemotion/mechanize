$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class SelectNoOptionsTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost:#{PORT}/form_select_noopts.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_not_nil(@form.fields.name('list').first)
    assert_nil(@form.list)
    page = @agent.submit(@form)
    assert_equal(0, page.links.length)
  end
end
