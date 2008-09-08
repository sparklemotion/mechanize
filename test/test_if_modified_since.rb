require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestIfModifiedSince < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_get_twice
    assert_equal(0, @agent.history.length)
    page = @agent.get('http://localhost/if_modified_since')
    assert_match(/You did not send/, page.body)

    assert_equal(1, @agent.history.length)
    page2 = @agent.get('http://localhost/if_modified_since')

    assert_equal(2, @agent.history.length)
    assert_equal(page.object_id, page2.object_id)
    assert_match(/You did not send/, page.body)
  end
end
