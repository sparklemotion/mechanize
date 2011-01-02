require "helper"

class TestRobots < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new { |a|
      a.robots = true
    }
  end

  def test_robots
    assert_equal "OK\n", @agent.get_file("http://localhost/robots")
    assert_raise(Mechanize::RobotsDisallowedError) {
      @agent.get_file("http://localhost/norobots")
    }
  end
end

