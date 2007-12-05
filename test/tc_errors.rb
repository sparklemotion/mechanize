$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class MechErrorsTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new
  end

  def test_bad_form_method
    page = @agent.get("http://localhost:#{PORT}/bad_form_test.html")
    assert_raise(RuntimeError) {
      @agent.submit(page.forms.first)
    }
  end

  def test_non_exist
    begin
      page = @agent.get("http://localhost:#{PORT}/bad_form_test.html")
    rescue RuntimeError => ex
      assert_equal("404", ex.inspect)
    end
  end

  def test_too_many_radio
    page = @agent.get("http://localhost:#{PORT}/form_test.html")
    form = page.forms.name('post_form1').first
    form.radiobuttons.each { |r| r.checked = true }
    assert_raise(RuntimeError) {
      @agent.submit(form)
    }
  end

  def test_unknown_agent
    assert_raise(RuntimeError) {
      @agent.user_agent_alias = "Aaron's Browser"
    }
  end

  def test_bad_url
    assert_raise(RuntimeError) {
      @agent.get('/foo.html')
    }
  end

  def test_unsupported_scheme
    assert_raise(RuntimeError) {
      @agent.get('ftp://server.com/foo.html')
    }
  end
end
