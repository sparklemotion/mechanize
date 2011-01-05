require "helper"

class TestRobots < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
    @robot = Mechanize.new { |a|
      a.robots = true
    }
  end

  def test_robots
    assert_equal "OK\n", @robot.get_file("http://localhost/robots")
    assert_raise(Mechanize::RobotsDisallowedError) {
      @robot.get_file("http://localhost/norobots")
    }
  end

  def test_robots_allowed?
    assert  @agent.robots_allowed?("http://localhost/robots")
    assert !@agent.robots_allowed?("http://localhost/norobots")

    assert !@agent.robots_disallowed?("http://localhost/robots")
    assert  @agent.robots_disallowed?("http://localhost/norobots")
  end

  def test_noindex
    assert_nothing_raised {
      @agent.get("http://localhost/noindex.html")
    }

    assert @robot.robots_allowed?("http://localhost/noindex.html")
    assert_raise(Mechanize::RobotsDisallowedError) {
      @robot.get("http://localhost/noindex.html")
    }
  end

  def test_nofollow
    page = @agent.get("http://localhost/nofollow.html")

    assert_nothing_raised {
      page.links[0].click
    }
    assert_nothing_raised {
      page.links[1].click
    }

    page = @robot.get("http://localhost/nofollow.html")

    assert_raise(Mechanize::RobotsDisallowedError) {
      page.links[0].click
    }
    assert_raise(Mechanize::RobotsDisallowedError) {
      page.links[1].click
    }
  end

  def test_rel_nofollow
    page = @agent.get("http://localhost/rel_nofollow.html")

    assert_nothing_raised {
      page.links[0].click
    }
    assert_nothing_raised {
      page.links[1].click
    }

    page = @robot.get("http://localhost/rel_nofollow.html")

    assert_nothing_raised {
      page.links[0].click
    }
    assert_raise(Mechanize::RobotsDisallowedError) {
      page.links[1].click
    }
  end
end
