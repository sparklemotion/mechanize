require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

class TestAuthHeaders < Test::Unit::TestCase
  def test_auth
    url = URI.parse('http://www.anthonychaves.net/tests.xml')
    digest = %Q!Digest realm="www.anthonychaves.net", qop="auth", algorithm=MD5, nonce="MTI0NTEyMTYyNjo0ZTY2MjhlZWMyZmM1ZjA0M2Y1Njc1MGU0YTA2MWY5OQ==", opaque="9f455d4e71e8d46a6d3aaef8bf8b0d9e"!
    v = Mechanize::Chain.new([
      Mechanize::Chain::AuthHeaders.new({(url.host) => :digest}, "anthony", "password", digest)
    ])
    
    hash = {
      :request => Net::HTTP::Get.new(url.request_uri),
      :uri => url
    }
    v.handle(hash) 
    actual_authorization = hash[:request]['Authorization'] 
    # The chain gave our request an Authorization header with client-generated values and derivatives.
    # They should be scrubbed before comparing to the expected result because they change
    # on each invokation
    actual_authorization.gsub!(/cnonce=\"\w+?\"/, "cnonce=\"scrubbed_cnonce\"").gsub!(/response=\"\w+?\"/, "response=\"scrubbed_response\"")
    
    expected_authorization = %Q!Digest username="anthony", qop=auth, uri="/tests.xml", algorithm="MD5", opaque="9f455d4e71e8d46a6d3aaef8bf8b0d9e", nonce="MTI0NTEyMTYyNjo0ZTY2MjhlZWMyZmM1ZjA0M2Y1Njc1MGU0YTA2MWY5OQ==", realm="www.anthonychaves.net", nc=00000001, cnonce="scrubbed_cnonce", response="scrubbed_response"!
    assert_equal(expected_authorization, actual_authorization)
  end
end
