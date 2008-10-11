require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class SelectNoOptionsTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost/form_select_noopts.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_not_nil(@form.field('list'))
    assert_nil(@form.list)
    page = @agent.submit(@form)
    assert_equal(0, page.links.length)
  end
end
