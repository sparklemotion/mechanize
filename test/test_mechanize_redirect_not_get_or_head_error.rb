require 'mechanize/test_case'

class TestMechanizeRedirectNotGetOrHead < Mechanize::TestCase

  def setup
    @agent = Mechanize.new
  end

  def test_to_s
    page = fake_page @agent

    error = Mechanize::RedirectNotGetOrHeadError.new(page, :put)

    assert_match(/ PUT /, error.to_s)
  end

end

