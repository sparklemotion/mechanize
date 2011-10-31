require 'helper'

class TestMechanizeHttpAuthChallenge < MiniTest::Unit::TestCase

  def setup
    @uri = URI 'http://example/'
    @AR = Mechanize::HTTP::AuthRealm
    @AC = Mechanize::HTTP::AuthChallenge
    @challenge = @AC.new 'Digest', 'realm' => 'r'
  end

  def test_realm_basic
    @challenge.scheme = 'Basic'

    expected = @AR.new 'Basic', @uri, 'r'

    assert_equal expected, @challenge.realm(@uri + '/foo')
  end

  def test_realm_digest
    expected = @AR.new 'Digest', @uri, 'r'

    assert_equal expected, @challenge.realm(@uri + '/foo')
  end

  def test_realm_unknown
    @challenge.scheme = 'Unknown'

    e = assert_raises Mechanize::Error do
      @challenge.realm(@uri + '/foo')
    end

    assert_equal 'unknown HTTP authentication scheme Unknown', e.message
  end

end

