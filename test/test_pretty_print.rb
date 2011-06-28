require "helper"

class TestPrettyPrint < MiniTest::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_pretty_print
    @agent.get("http://localhost/tc_pretty_print.html")
    pretty_string = @agent.pretty_print_inspect
    assert_match("{title \"tc_pretty_print.html\"}", pretty_string)
    assert_match(/\{frames[^"]*"http:\/\/meme/, pretty_string)
    assert_match(/\{iframes[^"]*"http:\/\/meme/, pretty_string)
    assert_match(
     "{links #<Mechanize::Page::Link \"Google\" \"http://google.com/\">}",
     pretty_string
                )
    assert_match("form1", pretty_string)
    assert_match("POST", pretty_string)
    assert_match("{file_uploads}", pretty_string)
  end
end
