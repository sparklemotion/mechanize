require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class MetaTest < Test::Unit::TestCase
  Meta = WWW::Mechanize::Page::Meta
  
  #
  # CONTENT_REGEXP test
  #
  
  def test_content_regexp
    r = Meta::CONTENT_REGEXP
    
    assert r =~ "0; url=http://localhost:8080/path"
    assert_equal "0", $1
    assert_equal "http://localhost:8080/path", $3
    
    assert r =~ "100.001; url=http://localhost:8080/path"
    assert_equal "100.001", $1
    assert_equal "http://localhost:8080/path", $3
    
    assert r =~ "0; url='http://localhost:8080/path'"
    assert_equal "0", $1
    assert_equal "http://localhost:8080/path", $3
    
    assert r =~ "0; url=\"http://localhost:8080/path\""
    assert_equal "0", $1
    assert_equal "http://localhost:8080/path", $3
    
    assert r =~ "0; url="
    assert_equal "0", $1
    assert_equal "", $3
    
    assert r =~ "0"
    assert_equal "0", $1
    assert_equal nil, $3
    
    assert r =~ "   0;   "
    assert_equal "0", $1
    assert_equal nil, $3
    
    assert r =~ "0; UrL=http://localhost:8080/path"
    assert_equal "0", $1
    assert_equal "http://localhost:8080/path", $3
  end
  
  #
  # parse test
  #
  
  def test_parse_documentation
    uri = URI.parse('http://current.com/')
  
    assert_equal ['5', 'http://example.com/'], Meta.parse("5;url=http://example.com/", uri)
    assert_equal ['5', 'http://current.com/'], Meta.parse("5;url=", uri) 
    assert_equal ['5', 'http://current.com/'], Meta.parse("5", uri) 
    assert_equal nil, Meta.parse("invalid content", uri)
  end
  
  def test_parse_returns_nil_if_no_delay_and_url_can_be_parsed
    uri = URI.parse('http://current.com/')
    
    assert_equal nil, Meta.parse("invalid content", uri)
    assert_equal nil, Meta.parse("invalid content", uri) {|delay, url| 'not nil' }
  end
end