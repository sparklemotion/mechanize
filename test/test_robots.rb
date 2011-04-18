require "helper"

class TestRobots < Test::Unit::TestCase
  def setup
    @agent = Mechanize.new
    @robot = Mechanize.new { |a|
      a.robots = true
    }
  end

  def test_mechanize_webrobots_http_get
    robotstxt = @agent.__send__(:webrobots_http_get, 'http://localhost/robots.txt')
    assert_not_equal '', robotstxt

    robotstxt = @agent.__send__(:webrobots_http_get, 'http://localhost/response_code?code=404')
    assert_equal '', robotstxt
  end

  def test_robots
    assert_equal "Welcome!", @robot.get("http://localhost/robots.html").title

    assert_raise(Mechanize::RobotsDisallowedError) {
      @robot.get("http://localhost/norobots.html")
    }
  end

  def test_robots_allowed_eh
    allowed    = URI.parse 'http://localhost/robots.html'
    disallowed = URI.parse 'http://localhost/norobots.html'
    assert  @agent.robots_allowed?(allowed)
    assert !@agent.robots_allowed?(disallowed)

    assert !@agent.robots_disallowed?(allowed)
    assert  @agent.robots_disallowed?(disallowed)
  end

  def test_noindex
    assert_nothing_raised {
      @agent.get("http://localhost/noindex.html")
    }

    assert @robot.robots_allowed?(URI.parse("http://localhost/noindex.html"))
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
