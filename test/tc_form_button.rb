require File.dirname(__FILE__) + "/helper"

class TestFormButtons < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_submit_button
    html = <<-END
    <html><body>
    <form><input type="submit" value="submit" /></form>
    </body></html>
    END
    page = WWW::Mechanize::Page.new(  nil, html_response, html, 200, @agent )
    assert_equal(1, page.forms.length)
    assert_equal(1, page.forms.first.buttons.length)
  end

  def test_button_button
    html = <<-END
    <html><body>
    <form><input type="button" value="submit" /></form>
    </body></html>
    END
    page = WWW::Mechanize::Page.new(  nil, html_response, html, 200, @agent )
    assert_equal(1, page.forms.length)
    assert_equal(1, page.forms.first.buttons.length)
  end

  def html_response
    { 'content-type' => 'text/html' }
  end
end
