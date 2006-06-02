$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class MechErrorsTest < Test::Unit::TestCase
  include TestMethods

  def test_content_type_error
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/bad_content_type")
    assert_raise(WWW::Mechanize::ContentTypeError) {
      page.root
    }
    begin
      page.root
    rescue WWW::Mechanize::ContentTypeError => ex
      assert_equal('text/xml', ex.content_type)
    end
  end

  def test_bad_form_method
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/bad_form_test.html")
    assert_raise(RuntimeError) {
      agent.submit(page.forms.first)
    }
  end

  def test_too_many_radio
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    page = agent.get("http://localhost:#{@port}/form_test.html")
    form = page.forms.name('post_form1').first
    form.radiobuttons.each { |r| r.checked = true }
    assert_raise(RuntimeError) {
      agent.submit(form)
    }
  end

  def test_unknown_agent
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    assert_raise(RuntimeError) {
      agent.user_agent_alias = "Aaron's Browser"
    }
  end

  def test_bad_url
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    assert_raise(RuntimeError) {
      agent.get('/foo.html')
    }
  end

  def test_unsupported_scheme
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    assert_raise(RuntimeError) {
      agent.get('ftp://server.com/foo.html')
    }
  end
end
