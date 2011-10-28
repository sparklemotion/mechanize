require 'helper'

class TestMechanizeHttpAuthChallenge < MiniTest::Unit::TestCase

  def test_auth_param
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 'realm=here'

    param = ac.auth_param

    assert_equal 'realm=here', param
  end

  def test_auth_param_bad_no_value
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 'realm='

    assert_nil ac.auth_param
  end

  def test_auth_param_bad_token
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 'realm'

    assert_nil ac.auth_param
  end

  def test_auth_param_bad_value
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 'realm="this '

    assert_nil ac.auth_param
  end

  def test_auth_param_quoted
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 'realm="this site"'

    param = ac.auth_param

    assert_equal 'realm="this site"', param
  end

  def test_parse
    ac = auth_challenge 'Basic realm=foo'

    expected = [
      'Basic realm=foo',
    ]

    assert_equal expected, ac.parse
  end

  def test_parse_multiple
    ac = auth_challenge 'Basic realm=foo, Digest realm=foo'

    expected = [
      'Basic realm=foo',
      'Digest realm=foo',
    ]

    assert_equal expected, ac.parse
  end

  def test_parse_multiple_blank
    ac = auth_challenge 'Basic realm=foo,, Digest realm=foo'

    expected = [
      'Basic realm=foo',
      'Digest realm=foo',
    ]

    assert_equal expected, ac.parse
  end

  def test_quoted_string
    ac = auth_challenge nil
    ac.scanner = StringScanner.new '"text"'

    string = ac.quoted_string

    assert_equal '"text"', string
  end

  def test_quoted_string_bad
    ac = auth_challenge nil
    ac.scanner = StringScanner.new '"text'

    assert_nil ac.quoted_string
  end

  def test_quoted_string_quote
    ac = auth_challenge nil
    ac.scanner = StringScanner.new '"escaped \\" here"'

    string = ac.quoted_string

    assert_equal '"escaped \\" here"', string
  end

  def test_quoted_string_quote_end
    ac = auth_challenge nil
    ac.scanner = StringScanner.new '"end \""'

    string = ac.quoted_string

    assert_equal '"end \""', string
  end

  def test_token
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 'text'

    string = ac.token

    assert_equal 'text', string
  end

  def test_token_space
    ac = auth_challenge nil
    ac.scanner = StringScanner.new 't ext'

    string = ac.token

    assert_equal 't', string
  end

  def test_token_special
    ac = auth_challenge nil
    ac.scanner = StringScanner.new "t\text"

    string = ac.token

    assert_equal 't', string
  end

  def auth_challenge header
    Mechanize::HTTP::AuthChallenge.new header
  end

end

