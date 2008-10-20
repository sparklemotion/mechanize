require File.expand_path(File.join(File.dirname(__FILE__), "helper"))
class SelectNoneTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost/form_select_none.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_equal("1", @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
  end
end
