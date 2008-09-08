require File.expand_path(File.join(File.dirname(__FILE__), '..', "helper"))

class TestCustomHeaders < Test::Unit::TestCase
  def test_handle
    v = WWW::Mechanize::Chain.new([
      WWW::Mechanize::Chain::CustomHeaders.new
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
