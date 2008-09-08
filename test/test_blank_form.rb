require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class BlankFormTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_blank_form_query_string
    page = @agent.get('http://localhost/tc_blank_form.html')
    form = page.forms.first
    query = form.build_query
    assert(query.length > 0)
    assert query.all? { |x| x[1] == '' }
  end
end

