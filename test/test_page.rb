require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

require 'cgi'

class TestPage < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_page_gets_charset_from_page
    page = @agent.get("http://localhost/tc_charset.html")
    assert_equal 'windows-1255', page.encoding
  end

  def test_double_semicolon
    page = @agent.get("http://localhost/http_headers?content-disposition=#{CGI.escape('attachment;; filename=fooooo')}")
    assert page.parser
  end

  def test_broken_charset
    page = @agent.get("http://localhost/http_headers?content-type=#{CGI.escape('text/html; charset=akldsjfhaldjfksh')}")
    assert page.parser
  end

  def test_mostly_broken_charset
    page = @agent.get("http://localhost/http_headers?content-type=#{CGI.escape('text/html; charset=ISO_8859-1')}")
    assert_equal 'ISO_8859-1', page.encoding
  end

  def test_another_mostly_broken_charset
    page = @agent.get("http://localhost/http_headers?content-type=#{CGI.escape('text/html; charset=UTF8')}")
    assert_equal 'UTF8', page.parser.encoding
    assert_equal 'UTF8', page.encoding
  end

  def test_upper_case_content_type
    page = @agent.get("http://localhost/http_headers?content-type=#{CGI.escape('text/HTML')}")
    assert_instance_of WWW::Mechanize::Page, page
    assert_equal 'text/HTML', page.content_type
  end

  def test_encoding_override_before_parser_initialized
    # document has a bad encoding information - windows-1255
    page = @agent.get("http://localhost/tc_bad_charset.html")
    # encoding is wrong, so user wants to force ISO-8859-2
    page.encoding = 'ISO-8859-2'
    assert_equal 'ISO-8859-2', page.encoding
  end

  def test_encoding_override_after_parser_was_initialized
    # document has a bad encoding information - windows-1255
    page = @agent.get("http://localhost/tc_bad_charset.html")
    page.parser
    # autodetection sets encoding to windows-1255
    assert_equal 'windows-1255', page.encoding
    # encoding is wrong, so user wants to force ISO-8859-2
    page.encoding = 'ISO-8859-2'
    assert_equal 'ISO-8859-2', page.encoding
  end

  def test_page_gets_charset_sent_by_server
    page = @agent.get("http://localhost/http_headers?content-type=#{CGI.escape('text/html; charset=UTF-8')}")
    assert_equal 'UTF-8', page.encoding
  end

  def test_set_encoding
    page = @agent.get("http://localhost/file_upload.html")
    page.encoding = 'UTF-8'
    assert_equal 'UTF-8', page.parser.encoding
  end

  def test_page_gets_yielded
    pages = nil
    @agent.get("http://localhost/file_upload.html") { |page|
      pages = page
    }
    assert pages
    assert_equal('File Upload Form', pages.title)
  end

  def test_title
    page = @agent.get("http://localhost/file_upload.html")
    assert_equal('File Upload Form', page.title)
  end

  def test_no_title
    page = @agent.get("http://localhost/no_title_test.html")
    assert_equal(nil, page.title)
  end

  def test_page_decoded_with_charset
    page = WWW::Mechanize::Page.new(
      URI.parse('http://tenderlovemaking.com/'),
      { 'content-type' => 'text/html; charset=EUC-JP' },
      '<html><body>hello</body></html>',
      400,
      @agent
    )
    assert_equal 'EUC-JP', page.parser.encoding
  end

  def test_find_form_with_hash
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

