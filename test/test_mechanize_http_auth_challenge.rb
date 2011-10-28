require 'helper'

class TestMechanizeHttpAuthChallenge < MiniTest::Unit::TestCase

  def test_auth_param
    ac = parser nil
    ac.scanner = StringScanner.new 'realm=here'

    param = ac.auth_param

    assert_equal %w[realm here], param
  end

  def test_auth_param_bad_no_value
    ac = parser nil
    ac.scanner = StringScanner.new 'realm='

    assert_nil ac.auth_param
  end

  def test_auth_param_bad_token
    ac = parser nil
    ac.scanner = StringScanner.new 'realm'

    assert_nil ac.auth_param
  end

  def test_auth_param_bad_value
    ac = parser nil
    ac.scanner = StringScanner.new 'realm="this '

    assert_nil ac.auth_param
  end

  def test_auth_param_quoted
    ac = parser nil
    ac.scanner = StringScanner.new 'realm="this site"'

    param = ac.auth_param

    assert_equal ['realm', '"this site"'], param
  end

  def test_parse
    ac = parser 'Basic realm=foo'

    expected = [
      challenge('Basic', { 'realm' => 'foo' }),
    ]

    assert_equal expected, ac.parse
  end

  def test_parse_multiple
    ac = parser 'Basic realm=foo, Digest realm=foo'

    expected = [
      challenge('Basic', { 'realm' => 'foo' }),
      challenge('Digest', { 'realm' => 'foo' }),
    ]

    assert_equal expected, ac.parse
  end

  def test_parse_multiple_blank
    ac = parser 'Basic realm=foo,, Digest realm=foo'

    expected = [
      challenge('Basic', { 'realm' => 'foo' }),
      challenge('Digest', { 'realm' => 'foo' }),
    ]

    assert_equal expected, ac.parse
  end

  def test_quoted_string
    ac = parser nil
    ac.scanner = StringScanner.new '"text"'

    string = ac.quoted_string

    assert_equal '"text"', string
  end

  def test_quoted_string_bad
    ac = parser nil
    ac.scanner = StringScanner.new '"text'

    assert_nil ac.quoted_string
  end

  def test_quoted_string_quote
    ac = parser nil
    ac.scanner = StringScanner.new '"escaped \\" here"'

    string = ac.quoted_string

    assert_equal '"escaped \\" here"', string
  end

  def test_quoted_string_quote_end
    ac = parser nil
    ac.scanner = StringScanner.new '"end \""'

    string = ac.quoted_string

    assert_equal '"end \""', string
  end

  def test_token
    ac = parser nil
    ac.scanner = StringScanner.new 'text'

    string = ac.token

    assert_equal 'text', string
  end

  def test_token_space
    ac = parser nil
    ac.scanner = StringScanner.new 't ext'

    string = ac.token

    assert_equal 't', string
  end

  def test_token_special
    ac = parser nil
    ac.scanner = StringScanner.new "t\text"

    string = ac.token

    assert_equal 't', string
  end

  def parser header
    Mechanize::HTTP::AuthChallenge.new header
  end

  def challenge scheme, params
    Mechanize::HTTP::AuthChallenge::Challenge.new scheme, params
  end

end

