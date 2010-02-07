require "helper"

class TestParameterResolver < Test::Unit::TestCase
  def test_handle_get
    v = Mechanize::Chain.new([
      Mechanize::Chain::ParameterResolver.new
    ])
    hash = {
      :uri    => URI.parse('http://google.com/'),
      :params => { :q => 'hello' },
      :verb   => :get
    }
    assert_nothing_raised {
      v.handle(hash)
    }
    assert_equal('q=hello', hash[:uri].query)
    assert_equal([], hash[:params])
  end

  def test_handle_post
    v = Mechanize::Chain.new([
      Mechanize::Chain::ParameterResolver.new
    ])
    hash = {
      :uri    => URI.parse('http://google.com/'),
      :params => { :q => 'hello' },
      :verb   => :post
    }
    assert_nothing_raised {
      v.handle(hash)
    }
    assert_equal('', hash[:uri].query.to_s)
    assert_equal({ :q => 'hello' }, hash[:params])
  end
end
