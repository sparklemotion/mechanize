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
end

