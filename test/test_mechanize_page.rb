require 'helper'
require 'cgi'

class TestMechanizePage < Test::Unit::TestCase

  WINDOWS_1255 = <<-HTML
<meta http-equiv="content-type" content="text/html; charset=windows-1255">
<title>hi</title>
  HTML

  BAD = <<-HTML
<meta http-equiv="content-type" content="text/html; charset=windows-1255">
<title>Bia\xB3ystok</title>
  HTML

  def setup
    @agent = Mechanize.new
    @uri = URI.parse 'http://example'
    @res = { 'content-type' => 'text/html' }
    @body = '<title>hi</title>'
  end

  def util_page body = @body, res = @res
    Mechanize::Page.new @uri, res, body, 200, @agent
  end

  def test_encoding
    page = util_page WINDOWS_1255

    assert_equal 'windows-1255', page.encoding
  end

  def test_encoding_equals
    page = util_page

    page.encoding = 'UTF-8'

    assert_equal 'UTF-8', page.encoding
    assert_equal 'UTF-8', page.parser.encoding
  end

  def test_encoding_equals_before_parser
    # document has a bad encoding information - windows-1255
    page = util_page BAD

    # encoding is wrong, so user wants to force ISO-8859-2
    page.encoding = 'ISO-8859-2'

    assert_equal 'ISO-8859-2', page.encoding
    assert_equal 'ISO-8859-2', page.parser.encoding
  end

  def test_encoding_equals_after_parser
    # document has a bad encoding information - windows-1255
    page = util_page BAD
    page.parser

    # autodetection sets encoding to windows-1255
    assert_equal 'windows-1255', page.encoding

    # encoding is wrong, so user wants to force ISO-8859-2
    page.encoding = 'ISO-8859-2'

    assert_equal 'ISO-8859-2', page.encoding
    assert_equal 'ISO-8859-2', page.parser.encoding
  end

  def test_title
    page = util_page

    assert_equal('hi', page.title)
  end

  def test_title_none
    page = util_page '' # invalid HTML

    assert_equal(nil, page.title)
  end

  def test_page_decoded_with_charset
    page = util_page @body, 'content-type' => 'text/html; charset=EUC-JP'

    assert_equal 'EUC-JP', page.encoding
    assert_equal 'EUC-JP', page.parser.encoding
  end

  def test_form
    page  = @agent.get("http://localhost/tc_form_action.html")

    form = page.form(:name => 'post_form1')
    assert form
    yielded = false

    form = page.form(:name => 'post_form1') { |f|
      yielded = true
      assert f
      assert_equal(form, f)
    }

    assert yielded

    form_by_action = page.form(:action => '/form_post?a=b&b=c')
    assert form_by_action
    assert_equal(form, form_by_action)
  end

end

