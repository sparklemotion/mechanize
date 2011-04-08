require "helper"

class VerbsTest < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_put
    page = @agent.put('http://localhost/verb', 'foo')
    assert_equal 1, @agent.history.length
    assert_equal 'PUT', page.header['X-Request-Method']
  end

  def test_delete
    page = @agent.delete('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 1, @agent.history.length
    assert_equal 'DELETE', page.header['X-Request-Method']
  end

  def test_head
    page = @agent.head('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 0, @agent.history.length
    assert_equal 'HEAD', page.header['X-Request-Method']
  end
end
