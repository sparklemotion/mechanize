require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class MechanizeFileTest < Test::Unit::TestCase
  def test_content_disposition
    file = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
           { 'content-disposition' => 'attachment; filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"', }
           )
    assert_equal('genome.jpeg', file.filename)

    file = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
           { 'content-disposition' => 'filename=genome.jpeg; modification-date="Wed, 12 Feb 1997 16:29:51 -0500"', }
           )
    assert_equal('genome.jpeg', file.filename)

    file = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
           { 'content-disposition' => 'filename=genome.jpeg', }
           )
    assert_equal('genome.jpeg', file.filename)
  end

  def test_from_uri
    file = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/foo'),
                                    {}
           )
    assert_equal('foo.html', file.filename)

    file = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/foo.jpg'),
                                    {}
           )
    assert_equal('foo.jpg', file.filename)

    file = WWW::Mechanize::File.new(
                                    URI.parse('http://localhost/foo.jpg')
           )
    assert_equal('foo.jpg', file.filename)
  end

  def test_no_uri
    file = WWW::Mechanize::File.new()
    assert_equal('index.html', file.filename)
  end
end
