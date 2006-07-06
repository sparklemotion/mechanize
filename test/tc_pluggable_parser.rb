$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'test/unit'
require 'rubygems'
require 'mechanize'
require 'test_includes'

class PluggableParserTest < Test::Unit::TestCase
  include TestMethods

  def setup
    @agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
  end

  def test_content_type_error
    page = @agent.get("http://localhost:#{PORT}/bad_content_type")
    page = WWW::Mechanize::Page.new(
                                    page.uri, 
                                    page.response, 
                                    page.body,
                                    page.code
                                   )
    assert_raise(WWW::Mechanize::ContentTypeError) {
      page.root
    }
    begin
      page.root
    rescue WWW::Mechanize::ContentTypeError => ex
      assert_equal('text/xml', ex.content_type)
    end
  end

  def test_content_type
    page = @agent.get("http://localhost:#{PORT}/content_type_test")
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

  def test_filter
    @agent.pluggable_parser.html = Filter
    page = @agent.get("http://localhost:#{PORT}/find_link.html")
    assert_kind_of(Filter, page)
    assert_equal(16, page.links.length)
    assert_not_nil(page.links.text('Net::DAAP::Client').first)
    assert_equal(1, page.links.text('Net::DAAP::Client').length)
  end

  def test_filter_hash
    @agent.pluggable_parser['text/html'] = Filter
    page = @agent.get("http://localhost:#{PORT}/find_link.html")
    assert_kind_of(Class, @agent.pluggable_parser['text/html'])
    assert_equal(Filter, @agent.pluggable_parser['text/html'])
    assert_kind_of(Filter, page)
    assert_equal(16, page.links.length)
    assert_not_nil(page.links.text('Net::DAAP::Client').first)
    assert_equal(1, page.links.text('Net::DAAP::Client').length)
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
    @agent.pluggable_parser.pdf = Filter
    page = @agent.get("http://localhost:#{PORT}/content_type_test?ct=application/pdf")
    assert_kind_of(Class, @agent.pluggable_parser['application/pdf'])
    assert_equal(Filter, @agent.pluggable_parser['application/pdf'])
    assert_kind_of(Filter, page)
  end

  def test_content_type_csv
    @agent.pluggable_parser.csv = Filter
    page = @agent.get("http://localhost:#{PORT}/content_type_test?ct=text/csv")
    assert_kind_of(Class, @agent.pluggable_parser['text/csv'])
    assert_equal(Filter, @agent.pluggable_parser['text/csv'])
    assert_kind_of(Filter, page)
  end

  def test_content_type_xml
    @agent.pluggable_parser.xml = Filter
    page = @agent.get("http://localhost:#{PORT}/content_type_test?ct=text/xml")
    assert_kind_of(Class, @agent.pluggable_parser['text/xml'])
    assert_equal(Filter, @agent.pluggable_parser['text/xml'])
    assert_kind_of(Filter, page)
  end
end
