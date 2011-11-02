require 'mechanize/test_case'

class TestIfModifiedSince < Mechanize::TestCase
  def test_get_twice
    assert_equal(0, @mech.history.length)
    page = @mech.get('http://localhost/if_modified_since')
    assert_match(/You did not send/, page.body)

    assert_equal(1, @mech.history.length)
    page2 = @mech.get('http://localhost/if_modified_since')

    assert_equal(2, @mech.history.length)
    assert_equal(page.object_id, page2.object_id)
    assert_match(/You did not send/, page.body)
  end
end
