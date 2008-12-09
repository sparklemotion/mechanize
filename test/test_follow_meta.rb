require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class FollowMetaTest < Test::Unit::TestCase
  def setup
    @agent = WWW::Mechanize.new
  end

  def test_dont_follow_meta_by_default
    page = @agent.get('http://localhost/tc_follow_meta.html')
    assert_equal('http://localhost/tc_follow_meta.html', page.uri.to_s)
    assert_equal(1, page.meta.length)
  end

  def test_follow_meta_if_set
    @agent.follow_meta_refresh = true

    page = @agent.get('http://localhost/tc_follow_meta.html')

    assert_equal(2, @agent.history.length)
    assert_equal('http://localhost/tc_follow_meta.html',
                 @agent.history[0].uri.to_s)
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal('http://localhost/index.html', @agent.history.last.uri.to_s)
  end

  def test_always_follow_302
    @agent.follow_meta_refresh = false
    page = @agent.get('http://localhost/response_code?code=302&ct=test/xml')
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal(2, @agent.history.length)
  end

  def test_infinite_refresh_throws_exception
    @agent.follow_meta_refresh = true
    assert_raises(WWW::Mechanize::RedirectLimitReachedError) {
      begin
        @agent.get('http://localhost/infinite_refresh')
      rescue WWW::Mechanize::RedirectLimitReachedError => ex
        raise ex
      end
    }
  end
  
  def test_dont_honor_http_refresh_by_default
    page = @agent.get('http://localhost/http_refresh?refresh_time=0')
    assert_equal('http://localhost/http_refresh?refresh_time=0', page.uri.to_s)
  end
  
  def test_honor_http_refresh_if_set
    @agent.follow_meta_refresh = true
    page = @agent.get('http://localhost/http_refresh?refresh_time=0')
    assert_equal('http://localhost/index.html', page.uri.to_s)
    assert_equal(2, @agent.history.length)
  end

  def test_honor_http_refresh_delay_if_set
    @agent.follow_meta_refresh = true
    class << @agent
      attr_accessor :slept
      def sleep *args
        @slept = args
      end
    end

    page = @agent.get('http://localhost/http_refresh?refresh_time=1')
    assert_equal [1], @agent.slept
  end

end
