require "helper"

class SelectNoOptionsTest < MiniTest::Unit::TestCase
  def setup
    @agent = Mechanize.new
    @page = @agent.get("http://localhost/form_select_noopts.html")
    @form = @page.forms.first
  end

  def test_select_default
    assert @form.field('list')
    assert_nil @form.list

    page = @agent.submit(@form)

    assert_equal(0, page.links.length)
  end
end
