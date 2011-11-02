require 'mechanize/test_case'

class SelectNoneTest < Mechanize::TestCase
  def setup
    super

    @page = @mech.get("http://localhost/form_select_none.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert_equal("1", @form.list)
    page = @mech.submit(@form)
    assert_equal(1, page.links.length)
    assert_equal(1, page.links_with(:text => 'list:1').length)
  end
end
