require "helper"

class TestUtil < Test::Unit::TestCase
  def test_from_native_charset
    assert_equal 'foo', Mechanize::Util.from_native_charset('foo', nil)
  end
end
