require "helper"

class TestMechanizeFile < MiniTest::Unit::TestCase
  def test_content_disposition
    file = Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
           { 'content-disposition' => 'attachment; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"', }
           )
    assert_equal('genome.jpeg', file.filename)

    file = Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
           { 'content-disposition' => 'filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"', }
           )
    assert_equal('genome.jpeg', file.filename)

    file = Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
           { 'content-disposition' => 'filename=genome.jpeg', }
           )
    assert_equal('genome.jpeg', file.filename)
  end

  def test_content_disposition_double_semicolon
    agent = Mechanize.new
    page = agent.get("http://localhost/http_headers?content-disposition=#{CGI.escape('attachment;; filename=fooooo')}")
    assert page.parser
  end

  def test_from_uri
    file = Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
                                    {}
           )
    assert_equal('foo.html', file.filename)

    file = Mechanize::File.new(
                                    URI.parse('http://localhost/foo.jpg'),
                                    {}
           )
    assert_equal('foo.jpg', file.filename)

    file = Mechanize::File.new(
                                    URI.parse('http://localhost/foo.jpg')
           )
    assert_equal('foo.jpg', file.filename)
  end

  def test_no_uri
    file = Mechanize::File.new()
    assert_equal('index.html', file.filename)
  end
end
