require File.dirname(__FILE__) + "/helper"

class TestPage < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
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
