require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

class TestResponseReader < Test::Unit::TestCase
  def test_handle_bad_response_code
    response = Object.new
    class << response
      def read_body
      end
      def code; 999; end
    end

    v = WWW::Mechanize::Chain.new([
      WWW::Mechanize::Chain::ResponseReader.new(response)
    ])
    assert_raises(WWW::Mechanize::ResponseCodeError) {
      begin
        v.handle({})
      rescue Exception => x
        assert_equal(999, x.response_code)
        raise x
      end
    }
  end
end
