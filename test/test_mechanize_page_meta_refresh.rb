require 'helper'

class TestMechanizePageMetaRefresh < Test::Unit::TestCase
  MetaRefresh = Mechanize::Page::MetaRefresh

  def test_CONTENT_REGEXP
    r = MetaRefresh::CONTENT_REGEXP

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

  def test_parse
    uri = URI.parse('http://example/here/')

    assert_equal ['5', 'http://b.example'],
                 MetaRefresh.parse("5;url=http://b.example", uri)
    assert_equal ['5', 'http://example/a'],
                 MetaRefresh.parse("5;url=http://example/a", uri)
    assert_equal ['5', 'http://example/here/test'],
                 MetaRefresh.parse("5;url=test", uri)
    assert_equal ['5', 'http://example/test'],
                 MetaRefresh.parse("5;url=/test", uri)
    assert_equal ['5', 'http://example/here/'],
                 MetaRefresh.parse("5;url=", uri)
    assert_equal ['5', 'http://example/here/'],
                 MetaRefresh.parse("5", uri)

    assert_nil MetaRefresh.parse("invalid content", uri)
  end

  def test_parse_block
    uri = URI 'http://example'
    yielded = false

    result = MetaRefresh.parse('5;url=/a', uri) { |delay, url|
      assert_equal '5', delay
      assert_equal 'http://example/a', url
      yielded = :yielded
    }

    assert yielded

    assert_equal :yielded, result
  end

  def test_parse_invalid
    uri = URI.parse('http://example/')

    assert_nil MetaRefresh.parse("invalid content", uri)
  end

end

