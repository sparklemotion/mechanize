require 'mechanize/test_case'

class PluggableParserTest < Mechanize::TestCase

  def test_content_type_error
    page = @mech.get("http://localhost/bad_content_type")

    e = assert_raises Mechanize::ContentTypeError do
      page = Mechanize::Page.new(page.uri,
                                 page.response,
                                 page.body,
                                 page.code)
    end

    assert_equal('text/xml', e.content_type)
  end

  def test_content_type
    page = @mech.get("http://localhost/content_type_test")
    assert_kind_of(Mechanize::Page, page)
  end

  class Filter < Mechanize::Page
    def initialize(uri=nil, response=nil, body=nil, code=nil)
      super(  uri,
            response,
            body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>'),
            code
           )
    end
  end

  class FileFilter < Mechanize::File
    def initialize(uri=nil, response=nil, body=nil, code=nil)
      super(  uri,
            response,
            body.gsub(/<body>/, '<body><a href="http://daapclient.rubyforge.org">Net::DAAP::Client</a>'),
            code
           )
    end
  end

  def test_file_saver
    @mech.pluggable_parser.html = Mechanize::FileSaver

    in_tmpdir do
      page = @mech.get('http://localhost:2000/form_no_action.html')
      length = page.response['Content-Length']
      file_length = File.stat('localhost/form_no_action.html').size

      assert_equal length.to_i, file_length
    end
  end

  def test_filter
    @mech.pluggable_parser.html = Filter
    page = @mech.get("http://localhost/find_link.html")

    assert_kind_of(Filter, page)

    assert_equal(19, page.links.length)
    assert_equal(1, page.links_with(:text => 'Net::DAAP::Client').length)
  end

  def test_filter_hash
    @mech.pluggable_parser['text/html'] = Filter
    page = @mech.get("http://localhost/find_link.html")
    assert_kind_of(Class, @mech.pluggable_parser['text/html'])
    assert_equal(Filter, @mech.pluggable_parser['text/html'])
    assert_kind_of(Filter, page)
    assert_equal(19, page.links.length)
    assert_equal(1, page.links_with(:text => 'Net::DAAP::Client').length)
  end

  def test_content_type_pdf
    @mech.pluggable_parser.pdf = FileFilter
    page = @mech.get("http://localhost/content_type_test?ct=application/pdf")
    assert_kind_of(Class, @mech.pluggable_parser['application/pdf'])
    assert_equal(FileFilter, @mech.pluggable_parser['application/pdf'])
    assert_kind_of(FileFilter, page)
  end

  def test_content_type_csv
    @mech.pluggable_parser.csv = FileFilter
    page = @mech.get("http://localhost/content_type_test?ct=text/csv")
    assert_kind_of(Class, @mech.pluggable_parser['text/csv'])
    assert_equal(FileFilter, @mech.pluggable_parser['text/csv'])
    assert_kind_of(FileFilter, page)
  end

  def test_content_type_xml
    @mech.pluggable_parser.xml = FileFilter
    page = @mech.get("http://localhost/content_type_test?ct=text/xml")
    assert_kind_of(Class, @mech.pluggable_parser['text/xml'])
    assert_equal(FileFilter, @mech.pluggable_parser['text/xml'])
    assert_kind_of(FileFilter, page)
  end

end
