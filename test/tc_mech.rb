$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'webrick'
require 'test/unit'
require 'rubygems'
require 'mechanize'

class MechMethodsTest < Test::Unit::TestCase
  def setup
    @server = Thread.new {
      s = WEBrick::HTTPServer.new(
        :Port           => 0,
        :DocumentRoot   => Dir::pwd + "/htdocs",
        :Logger         => Logger.new(nil),
        :AccessLog      => Logger.new(nil)
      )
      @port = s.config[:Port]

      s.start
    }

    begin
      Net::HTTP.get(URI.parse("http://localhost:#{@port}/"))
    rescue
      sleep 2
      retry
    end
  end

  def test_history
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    0.upto(25) do |i|
      assert_equal(i, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
    page = agent.get("http://localhost:#{@port}/form_test.html")

    assert_equal("http://localhost:#{@port}/form_test.html",
      agent.history.last.uri.to_s)
    assert_equal("http://localhost:#{@port}/",
      agent.history[-2].uri.to_s)
  end

  def test_max_history
    agent = WWW::Mechanize.new { |a| a.log = Logger.new(nil) }
    agent.max_history = 10
    0.upto(10) do |i|
      assert_equal(i, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
    
    0.upto(10) do |i|
      assert_equal(10, agent.history.size)
      page = agent.get("http://localhost:#{@port}/")
    end
  end
end
