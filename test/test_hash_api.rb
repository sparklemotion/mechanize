require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestHashApi < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_title
    page = @agent.get(:url => "http://localhost/file_upload.html")
    assert_equal('File Upload Form', page.title)
  end

  def test_page_gets_yielded
    pages = nil
    @agent.get(:url => "http://localhost/file_upload.html") { |page|
      pages = page
    }
    assert pages
    assert_equal('File Upload Form', pages.title)
  end

  def test_get_with_params
    page = @agent.get(:url => 'http://localhost/', :params => { :q => 'hello' })
    assert_equal('http://localhost/?q=hello', page.uri.to_s)
  end

  def test_get_with_referer
    request = nil
    @agent.pre_connect_hooks << lambda { |params|
      request = params[:request]
    }

    @agent.get( :url => 'http://localhost/',
                :referer => URI.parse('http://google.com/')
              )

    assert request
    assert_equal 'http://google.com/', request['Referer']

    @agent.get( :url => 'http://localhost/',
                :params => [],
                :referer => 'http://tenderlovemaking.com/')
    assert_equal 'http://tenderlovemaking.com/', request['Referer']
  end
end
