require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

class TestURIResolver < Test::Unit::TestCase
  def test_handle
    v = WWW::Mechanize::Chain.new([
      WWW::Mechanize::Chain::URIResolver.new(Hash.new { |h,k|
        h[k] = lambda { |u,r| u }
      })
    ])
    assert_raises(ArgumentError) { v.handle({}) }
    assert_nothing_raised { v.handle({:uri => 'http://google.com/'}) }
    assert_raises(RuntimeError) { v.handle({:uri => 'google'}) }
  end
end
