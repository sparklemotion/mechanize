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
end

