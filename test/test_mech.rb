require "helper"

class TestMechMethods < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
  end

  def test_forms_google
    page = @agent.get("http://localhost/google.html")
    search = page.forms.find { |f| f.name == "f" }
    assert_not_nil(search)
    assert_not_nil(search.field_with(:name => 'q'))
    assert_not_nil(search.field_with(:name => 'hl'))
    assert_not_nil(search.fields.find { |f| f.name == 'ie' })
  end

  def test_new_find
    page = @agent.get("http://localhost/frame_test.html")
    assert_equal(3, page.frames.size)

    find_orig = page.frames.find_all { |f| f.name == 'frame1' }
    find1 = page.frames_with(:name => 'frame1')

    find_orig.zip(find1).each { |a,b|
      assert_equal(a, b)
    }
  end

end
