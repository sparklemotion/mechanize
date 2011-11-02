require 'mechanize/test_case'

class TestMechanizePage < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example/'
  end

  def test_parser_no_attributes
    body = <<-BODY
<html>
  <meta>
  <head><title></title>
  <body>
    <a>Hello</a>
    <a><img /></a>
    <form>
      <input />
      <select>
        <option />
      </select>
      <textarea></textarea>
    </form>
    <frame></frame>
  </body>
</html>
    BODY

    page = Mechanize::Page.new(@uri, { 'content-type' => 'text/html' }, body,
                               200, @mech)

    # HACK weak assertion
    assert_kind_of Nokogiri::HTML::Document, page.root
  end

end
