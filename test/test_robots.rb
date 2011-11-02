require 'mechanize/test_case'

class TestRobots < Mechanize::TestCase

  def setup
    @mech = Mechanize.new
    @robot = Mechanize.new { |a|
      a.robots = true
    }
  end

  def test_robots
    assert_equal "Welcome!", @robot.get("http://localhost/robots.html").title

    assert_raises Mechanize::RobotsDisallowedError do
      @robot.get("http://localhost/norobots.html")
    end
  end

  def test_robots_allowed_eh
    allowed    = URI.parse 'http://localhost/robots.html'
    disallowed = URI.parse 'http://localhost/norobots.html'
    assert  @mech.agent.robots_allowed?(allowed)
    assert !@mech.agent.robots_allowed?(disallowed)

    assert !@mech.agent.robots_disallowed?(allowed)
    assert  @mech.agent.robots_disallowed?(disallowed)
  end

  def test_noindex
    @mech.get("http://localhost/noindex.html")

    assert @robot.agent.robots_allowed? URI("http://localhost/noindex.html")

    assert_raises Mechanize::RobotsDisallowedError do
      @robot.get("http://localhost/noindex.html")
    end
  end

  def test_nofollow
    page = @mech.get("http://localhost/nofollow.html")

    page.links[0].click
    page.links[1].click

    page = @robot.get("http://localhost/nofollow.html")

    assert_raises Mechanize::RobotsDisallowedError do
      page.links[0].click
    end
    assert_raises Mechanize::RobotsDisallowedError do
      page.links[1].click
    end
  end

  def test_rel_nofollow
    page = @mech.get("http://localhost/rel_nofollow.html")

    page.links[0].click
    page.links[1].click

    page = @robot.get("http://localhost/rel_nofollow.html")

    page.links[0].click

    assert_raises Mechanize::RobotsDisallowedError do
      page.links[1].click
    end
  end

end

