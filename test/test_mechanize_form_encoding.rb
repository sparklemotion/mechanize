# coding: utf-8
require "helper"

class TestMechanizeFormEncoding < Test::Unit::TestCase

  # Encoding test should do with non-utf-8 characters

  MULTIBYTE_VALUE = "テスト" # "test" in Japanese UTF-8 encoding
  MULTIBYTE_ENCODING = 'Shift_JIS' # one of Japanese encoding
  encoded_value = "\x83\x65\x83\x58\x83\x67" # "test" in Japanese Shift_JIS encoding
  encoded_value.force_encoding(::Encoding::SHIFT_JIS) if encoded_value.respond_to?(:force_encoding)
  pct_escaped = CGI.escape(encoded_value) # same to Util.build_query_string
  EXPECTED_MULTIBYTE_QUERY= "first_name=#{pct_escaped}&first_name=&gender=&green%5Beggs%5D="

  FROM_NATIVE_CHARSET_USES_ICONV = RUBY_VERSION < '1.9.2'
  ENCODING_MISMATCH = if FROM_NATIVE_CHARSET_USES_ICONV
                        Iconv::IllegalSequence
                      else
                        Encoding::UndefinedConversionError
                      end

  RAILS3_HACK_RESULT = /\Autf8=%E2%9C%93/

  def setup
    @agent = Mechanize.new
  end

  def server_received
    @agent.page.at('div#query').inner_text
  end

  # note: rails_3_encoding_hack_form_test.html has html-escaped UTF-8 value in hidden
  #       Mechanize parses this html as ISO-8859-1, because html-escaped value is ASCII

  def test_post_with_form_accept_charset
    page = @agent.get("http://localhost/rails_3_encoding_hack_form_test.html")
    form = page.forms.first
    form.field('user_session[email]').value = 'email@example.com'

    assert_not_equal 'UTF-8', page.encoding
    assert_equal 'UTF-8', form.encoding
    assert_nothing_raised(ENCODING_MISMATCH){ form.submit }
    assert_match RAILS3_HACK_RESULT, server_received
  end

  def test_post_with_form_wrong_accept_charset
    page = @agent.get("http://localhost/rails_3_encoding_hack_form_test.html")
    form = page.forms.first
    form.field('user_session[email]').value = 'email@example.com'
    form.encoding = 'ISO-8859-1'

    assert_not_equal 'UTF-8', form.encoding
    assert_raise(ENCODING_MISMATCH){ form.submit }
  end

  unless FROM_NATIVE_CHARSET_USES_ICONV
    def test_post_multibytes_as_ascii
      page = @agent.get("http://localhost/rails_3_encoding_hack_form_test.html")
      form = page.forms.first
      form.field('user_session[email]').value = 'email@example.com'
      form.encoding = 'ISO-8859-1', {:undef => :replace}

      assert_nothing_raised(ENCODING_MISMATCH){ form.submit }
      assert_not_match RAILS3_HACK_RESULT, server_received
    end
  end


  def test_post_multibytes_raises_error_without_encoding_infomation
    page = @agent.get("http://localhost/form_set_fields.html")
    form = page.forms.first
    form['first_name'] = MULTIBYTE_VALUE

    assert_not_equal MULTIBYTE_ENCODING, form.encoding
    assert_raise(ENCODING_MISMATCH){ form.submit }
  end

  def test_post_multibytes_with_page_encoding
    page = @agent.get("http://localhost/form_set_fields.html")
    page.encoding = MULTIBYTE_ENCODING # set correct encoding to page
    form = page.forms.first
    form['first_name'] = MULTIBYTE_VALUE

    assert_equal MULTIBYTE_ENCODING, form.encoding
    assert_nothing_raised(ENCODING_MISMATCH){ form.submit }
    assert_equal EXPECTED_MULTIBYTE_QUERY, server_received
  end

  def test_post_multibytes_with_form_encoding
    page = @agent.get("http://localhost/form_set_fields.html")
    form = page.forms.first
    form.encoding = MULTIBYTE_ENCODING # set correct encoding to form
    form['first_name'] = MULTIBYTE_VALUE

    assert_equal MULTIBYTE_ENCODING, form.encoding
    assert_nothing_raised(ENCODING_MISMATCH){ form.submit }
    assert_equal EXPECTED_MULTIBYTE_QUERY, server_received
  end

  if FROM_NATIVE_CHARSET_USES_ICONV
    def test_post_multibytes_failure_logged
      sio = StringIO.new
      @agent.log = Logger.new(sio)
      @agent.log.level = Logger::INFO
      page = @agent.get("http://localhost/form_set_fields.html")
      form = page.forms.first
      form.encoding = 'utf-eight'
      form['first_name'] = MULTIBYTE_VALUE

      assert_nothing_raised(ENCODING_MISMATCH){ form.submit }
      assert_not_equal EXPECTED_MULTIBYTE_QUERY, server_received
      assert_match /from_native_charset: Iconv::InvalidEncoding: utf-eight/, sio.string

      Mechanize.log = nil
    end
  end
end
