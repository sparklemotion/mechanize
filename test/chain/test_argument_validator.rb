require "helper"

class TestURIResolver < Test::Unit::TestCase
  def test_handle
    r = Mechanize::URIResolver.new
    v = Mechanize::Chain.new([
      Mechanize::Chain::URIResolver.new(r)
    ])

    e = assert_raises ArgumentError do
      v.handle({})
    end

    assert_equal 'uri must be specified', e.message
  end
end
