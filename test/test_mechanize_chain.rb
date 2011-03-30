require 'helper'

class TestMechanizeChain < Test::Unit::TestCase

  def test_self_handle
    options = {
      :headers => { :etag => '0' },
      :request => Net::HTTP::Get.new('/'),
    }

    Mechanize::Chain.handle [Mechanize::Chain::CustomHeaders.new], options

    assert_equal %w[0], options[:request].to_hash['etag']
  end

end

