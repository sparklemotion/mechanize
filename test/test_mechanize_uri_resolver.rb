# coding: utf-8

require 'helper'
require 'mechanize/uri_resolver'

class TestMechanizeURIResolver < Test::Unit::TestCase

  def setup
    @r = Mechanize::URIResolver.new
  end

  def test_resolve_bad_uri
    e = assert_raises ArgumentError do
      @r.resolve 'google'
    end

    assert_equal 'absolute URL needed (not google)', e.message
  end

  def test_resolve_utf8
    uri = 'http://example?q=ü'

    resolved = @r.resolve uri

    assert_equal '/?q=%C3%BC', resolved.request_uri
  end

end

