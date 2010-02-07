require "helper"

class TestCustomHeaders < Test::Unit::TestCase
  def test_handle
    v = Mechanize::Chain.new([
      Mechanize::Chain::CustomHeaders.new
    ])
    url = URI.parse('http://tenderlovemaking.com/')
    hash = {
      :request => Net::HTTP::Get.new(url.request_uri),
      :headers => { 'Content-Length' => 300 }
    }
    v.handle(hash)
    headers = hash[:request].to_hash
    assert(headers.key?('content-length'))
    assert_equal([300], headers['content-length'])
  end
end
