require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class VerbsTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_put
    page = @agent.put('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 1, @agent.history.length
    assert_equal('method: PUT', page.body)
  end

  def test_delete
    page = @agent.delete('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 1, @agent.history.length
    assert_equal('method: DELETE', page.body)
  end

  def test_head
    page = @agent.head('http://localhost/verb', { 'q' => 'foo' })
    assert_equal 0, @agent.history.length
    assert_equal('method: HEAD', page.body)
  end
end
