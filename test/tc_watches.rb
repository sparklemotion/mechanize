require File.dirname(__FILE__) + "/helper"

class Area
  attr_reader :name

  def initialize(node)
    @name = node['name']
  end
end

class WatchesMechTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_watches
    page = @agent.get("http://localhost/find_link.html")
    page.watch_for_set = { 'area' => Area }
    watches = page.watches
    assert_equal(3, watches['area'].size)
    assert_nil(watches['area'][0].name)
    assert_equal('Marty', watches['area'][1].name)
    assert_nil(watches['area'][2].name)
  end
end
