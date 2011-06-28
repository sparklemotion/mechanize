require 'helper'

class TestMechanizeRedirectNotGetOrHead < MiniTest::Unit::TestCase

  def setup
    @agent = Mechanize.new
  end

  def test_to_s
    page = MechTestHelper.fake_page(@agent)

    error = Mechanize::RedirectNotGetOrHeadError.new(page, :put)

    assert_match(/ PUT /, error.to_s)
  end

end

