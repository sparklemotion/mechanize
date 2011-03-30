require 'helper'

class TestMechanizeChain < Test::Unit::TestCase

  def  est_self_handle
    r = Mechanize::URIResolver.new

    uri = Mechanize::Chain.handle([Mechanize::Chain::URIResolver.new(r)],
                                  :uri => 'foo', :referer => 'http://example/')

    assert_equal 'http://example/foo', uri.to_s
  end

end

