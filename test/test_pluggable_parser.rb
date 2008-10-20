require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class PluggableParserTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_content_type_error
    page = @agent.get("http://localhost/bad_content_type")
    assert_raise(WWW::Mechanize::ContentTypeError) {
      page = WWW::Mechanize::Page.new(
                                      page.uri, 
                                      page.response, 
                                      page.body,
                                      page.code
                                     )
    }
    begin
      page = WWW::Mechanize::Page.new(
                                      page.uri, 
                                      page.response, 
                                      page.body,
                                      page.code
                                     )
    rescue WWW::Mechanize::ContentTypeError => ex
      assert_equal('text/xml', ex.content_type)
    end
  end

  def test_content_type
    page = @agent.get("http://localhost/content_type_test")
    assert_kind_of(WWW::Mechanize::Page, page)
  end

  class Filter < WWW::Mechanize::Page
    def initialize(uri=nil, response=nil, body=nil, code=nil)
      super(  uri,
            response,
            body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>'),
            code
           )
    end
  end

  class FileFilter < WWW::Mechanize::File
    def initialize(uri=nil, response=nil, body=nil, code=nil)
      super(  uri,
            response,
            body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>'),
            code
           )
    end
  end

  def test_filter
    @agent.pluggable_parser.html = Filter
    page = @agent.get("http://localhost/find_link.html")
    assert_kind_of(Filter, page)
    assert_equal(19, page.links.length)
    assert_not_nil(page.link_with(:text => 'Net::DAAP::Client'))
    assert_equal(1, page.links_with(:text => 'Net::DAAP::Client').length)
  end

  def test_filter_hash
    @agent.pluggable_parser['text/html'] = Filter
    page = @agent.get("http://localhost/find_link.html")
    assert_kind_of(Class, @agent.pluggable_parser['text/html'])
    assert_equal(Filter, @agent.pluggable_parser['text/html'])
    assert_kind_of(Filter, page)
    assert_equal(19, page.links.length)
    assert_not_nil(page.link_with(:text => 'Net::DAAP::Client'))
    assert_equal(1, page.links_with(:text => 'Net::DAAP::Client').length)
  end

  def test_file_saver
    @agent.pluggable_parser.html = WWW::Mechanize::FileSaver
    page = @agent.get('http://localhost:2000/form_no_action.html')
    length = page.response['Content-Length']
    file_length = nil
    File.open("localhost/form_no_action.html", "r") { |f|
      file_length = f.read.length
    }
    FileUtils.rm_rf("localhost")
    assert_equal(length.to_i, file_length)
  end

  def test_content_type_pdf
    @agent.pluggable_parser.pdf = FileFilter
    page = @agent.get("http://localhost/content_type_test?ct=application/pdf")
    assert_kind_of(Class, @agent.pluggable_parser['application/pdf'])
    assert_equal(FileFilter, @agent.pluggable_parser['application/pdf'])
    assert_kind_of(FileFilter, page)
  end

  def test_content_type_csv
    @agent.pluggable_parser.csv = FileFilter
    page = @agent.get("http://localhost/content_type_test?ct=text/csv")
    assert_kind_of(Class, @agent.pluggable_parser['text/csv'])
    assert_equal(FileFilter, @agent.pluggable_parser['text/csv'])
    assert_kind_of(FileFilter, page)
  end

  def test_content_type_xml
    @agent.pluggable_parser.xml = FileFilter
    page = @agent.get("http://localhost/content_type_test?ct=text/xml")
    assert_kind_of(Class, @agent.pluggable_parser['text/xml'])
    assert_equal(FileFilter, @agent.pluggable_parser['text/xml'])
    assert_kind_of(FileFilter, page)
  end

  def test_file_saver_no_path
    url = URI::HTTP.new('http', nil, 'example.com', nil, nil, '', nil, nil, nil)
    fs = WWW::Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/index.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_file_saver_slash
    url = URI::HTTP.new('http', nil, 'example.com', nil, nil, '/', nil, nil, nil)
    fs = WWW::Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/index.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_file_saver_slash_file
    url = URI::HTTP.new('http', nil, 'example.com', nil, nil, '/foo.html', nil, nil, nil)
    fs = WWW::Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/foo.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_file_saver_long_path_no_file
    url = URI::HTTP.new('http', nil, 'example.com', nil, nil, '/one/two/', nil, nil, nil)
    fs = WWW::Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/one/two/index.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_file_saver_long_path
    url = URI::HTTP.new('http', nil, 'example.com', nil, nil, '/one/two/foo.html', nil, nil, nil)
    fs = WWW::Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/one/two/foo.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end
end
