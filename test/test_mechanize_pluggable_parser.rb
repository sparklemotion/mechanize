require 'mechanize/test_case'

class TestMechanizePluggableParser < Mechanize::TestCase

  def setup
    super

    @pp = @mech.pluggable_parser
  end

  def test_aref
    @pp['text/html'] = Mechanize::Download

    assert_equal Mechanize::Download, @pp['text/html']
  end

  def test_csv
    @pp.csv = Mechanize::Download

    assert_equal Mechanize::Download, @pp['text/csv']
  end

  def test_html
    assert_equal Mechanize::Page, @pp['text/html']

    @pp.html = Mechanize::Download

    assert_equal Mechanize::Download, @pp['text/html']
  end

  def test_parser
    assert_nil @pp['text/xml']

    assert_equal Mechanize::File, @pp.parser('text/xml')
  end

  def test_pdf
    @pp.pdf = Mechanize::Download

    assert_equal Mechanize::Download, @pp['application/pdf']
  end

  def test_xml
    assert_nil @pp['text/xml']

    @pp.xml = Mechanize::Download

    assert_equal Mechanize::Download, @pp['text/xml']
  end

end

