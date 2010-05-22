require "helper"

class TestHeaderResolver < Test::Unit::TestCase
  def setup
    @chain = Mechanize::Chain.new([
      Mechanize::Chain::HeaderResolver.new(
        Mechanize::CookieJar.new,
        'foobar',
        true,
        {
          'hello' => 'world',
          'Content-Type' => 'utf-8'
        }
      )
    ])
  end

  def test_handle
    hash = {
      :request => {},
      :uri => URI.parse('http://google.com/')
    }
    @chain.handle(hash)
    assert_equal 'world', hash[:request]['hello']
    assert_equal 'utf-8', hash[:request]['Content-Type']
  end
end
