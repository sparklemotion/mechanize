require 'mechanize/test_case'

class SelectNoOptionsTest < Mechanize::TestCase
  def setup
    super

    @page = @mech.get("http://localhost/form_select_noopts.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert @form.field('list')
    assert_nil @form.list

    page = @mech.submit(@form)

    assert_equal(0, page.links.length)
  end
end
