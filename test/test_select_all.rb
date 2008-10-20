require File.expand_path(File.join(File.dirname(__FILE__), "helper"))
class SelectAllTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
    @page = @agent.get("http://localhost/form_select_all.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_equal("6", @form.list)
    page = @agent.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:6').length)
  end
end
