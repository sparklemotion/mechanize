require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestUtil < Test::Unit::TestCase
  def test_from_native_charset
    assert_equal 'foo', Mechanize::Util.from_native_charset('foo', nil)
  end
end
