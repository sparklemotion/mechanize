require "helper"

class MechErrorsTest < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_bad_form_method
    page = @agent.get("http://localhost/bad_form_test.html")
    assert_raise ArgumentError do
      @agent.submit(page.forms.first)
    end
  end

  def test_non_exist
    begin
      @agent.get("http://localhost/bad_form_test.html")
    rescue RuntimeError => ex
      assert_equal("404", ex.inspect)
    end
  end

  def test_too_many_radio
    page = @agent.get("http://localhost/form_test.html")
    form = page.form_with(:name => 'post_form1')
    form.radiobuttons.each { |r| r.checked = true }
    assert_raise Mechanize::Error do
      @agent.submit(form)
    end
  end

  def test_unknown_agent
    assert_raise ArgumentError do
      @agent.user_agent_alias = "Aaron's Browser"
    end
  end

  def test_bad_url
    assert_raise ArgumentError do
      @agent.get('/foo.html')
    end
  end

  def test_unsupported_scheme
    assert_raise(Mechanize::UnsupportedSchemeError) {
      @agent.get('ftp://server.com/foo.html')
    }
  end
end
