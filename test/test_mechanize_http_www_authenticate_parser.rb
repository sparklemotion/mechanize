require 'helper'

class TestMechanizeHttpWwwAuthenticateParser < MiniTest::Unit::TestCase

  def setup
    @parser = Mechanize::HTTP::WWWAuthenticateParser.new
  end

  def test_auth_param
    @parser.scanner = StringScanner.new 'realm=here'

    param = @parser.auth_param

    assert_equal %w[realm here], param
  end

  def test_auth_param_bad_no_value
    @parser.scanner = StringScanner.new 'realm='

    assert_nil @parser.auth_param
  end

  def test_auth_param_bad_token
    @parser.scanner = StringScanner.new 'realm'

    assert_nil @parser.auth_param
  end

  def test_auth_param_bad_value
    @parser.scanner = StringScanner.new 'realm="this '

    assert_nil @parser.auth_param
  end

  def test_auth_param_quoted
    @parser.scanner = StringScanner.new 'realm="this site"'

    param = @parser.auth_param

    assert_equal ['realm', 'this site'], param
  end

  def test_parse
    expected = [
      challenge('Basic', { 'realm' => 'foo' }),
    ]

    assert_equal expected, @parser.parse('Basic realm=foo')
  end

  def test_parse_multiple
    expected = [
      challenge('Basic', { 'realm' => 'foo' }),
      challenge('Digest', { 'realm' => 'foo' }),
    ]

    assert_equal expected, @parser.parse('Basic realm=foo, Digest realm=foo')
  end

  def test_parse_multiple_blank
    expected = [
      challenge('Basic', { 'realm' => 'foo' }),
      challenge('Digest', { 'realm' => 'foo' }),
    ]

    assert_equal expected, @parser.parse('Basic realm=foo,, Digest realm=foo')
  end

  def test_parse_ntlm_init
    expected = [
      challenge('NTLM', nil),
    ]

    assert_equal expected, @parser.parse('NTLM')
  end

  def test_parse_ntlm_type_2_3
    expected = [
      challenge('NTLM', 'foo='),
    ]

    assert_equal expected, @parser.parse('NTLM foo=')
  end

  def test_quoted_string
    @parser.scanner = StringScanner.new '"text"'

    string = @parser.quoted_string

    assert_equal 'text', string
  end

  def test_quoted_string_bad
    @parser.scanner = StringScanner.new '"text'

    assert_nil @parser.quoted_string
  end

  def test_quoted_string_quote
    @parser.scanner = StringScanner.new '"escaped \\" here"'

    string = @parser.quoted_string

    assert_equal 'escaped \\" here', string
  end

  def test_quoted_string_quote_end
    @parser.scanner = StringScanner.new '"end \""'

    string = @parser.quoted_string

    assert_equal 'end \"', string
  end

  def test_token
    @parser.scanner = StringScanner.new 'text'

    string = @parser.token

    assert_equal 'text', string
  end

  def test_token_space
    @parser.scanner = StringScanner.new 't ext'

    string = @parser.token

    assert_equal 't', string
  end

  def test_token_special
    @parser.scanner = StringScanner.new "t\text"

    string = @parser.token

    assert_equal 't', string
  end

  def challenge scheme, params
    Mechanize::HTTP::AuthChallenge.new scheme, params
  end

end

