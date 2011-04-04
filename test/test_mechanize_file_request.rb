require 'helper'

class TestMechanizeFileRequest < Test::Unit::TestCase

  def test_initialize
    uri = URI.parse 'http://example/'

    r = Mechanize::FileRequest.new uri

    assert_equal uri, r.uri
    assert_equal '/', r.path

    assert_respond_to r, :[]=
    assert_respond_to r, :add_field
    assert_respond_to r, :each_header
  end

end

