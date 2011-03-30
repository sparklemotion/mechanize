require 'helper'

class TestMechanizeChain < Test::Unit::TestCase

  def test_self_handle
    r = Mechanize::URIResolver.new

    ref = Object.new
    def ref.uri() URI.parse 'http://example/' end

    options = { :uri => '/foo', :referer => ref }

    Mechanize::Chain.handle [Mechanize::Chain::URIResolver.new(r)], options

    assert_equal 'http://example/foo', options[:uri].to_s
  end

end

