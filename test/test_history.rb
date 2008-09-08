require File.expand_path(File.join(File.dirname(__FILE__), "helper"))

class TestHistory < Test::Unit::TestCase
  def setup
    @agent    = WWW::Mechanize.new
    @history  = WWW::Mechanize::History.new
  end

  def test_push
    assert_equal(0, @history.length)

    page = @agent.get("http://localhost/tc_bad_links.html")
    x = @history.push(page)
    assert_equal(x, @history)
    assert_equal(1, @history.length)
    assert(@history.visited?(page))
    assert(@history.visited?(page.uri))
    assert(@history.visited?(page.uri.to_s))
    assert_equal(page, @history.visited_page(page))
    assert_equal(page, @history.visited_page(page.uri))
    assert_equal(page, @history.visited_page(page.uri.to_s))

    @history.push(@agent.get("/tc_bad_links.html"))
    assert_equal(2, @history.length)
  end

  def test_shift
    assert_equal(0, @history.length)
    page = @agent.get("http://localhost/tc_bad_links.html")
    @history.push(page)
    assert_equal(1, @history.length)

    @history.push(@agent.get("/tc_bad_links.html"))
    assert_equal(2, @history.length)

    @history.push(@agent.get("/index.html"))
    assert_equal(3, @history.length)

    page2 = @history.shift
    assert_equal(page, page2)
    assert_equal(2, @history.length)

    @history.shift
    assert_equal(1, @history.length)
    assert_equal(false, @history.visited?(page))

    @history.shift
    assert_equal(0, @history.length)

    assert_nil(@history.shift)
    assert_equal(0, @history.length)
  end

  def test_pop
    assert_equal(0, @history.length)
    page = @agent.get("http://localhost/tc_bad_links.html")
    @history.push(page)
    assert_equal(1, @history.length)

    page2 = @agent.get("/index.html")
    @history.push(page2)
    assert_equal(2, @history.length)
    assert_equal(page2, @history.pop)
    assert_equal(1, @history.length)
    assert_equal(true, @history.visited?(page))
    assert_equal(false, @history.visited?(page2))
    assert_equal(page, @history.pop)
    assert_equal(0, @history.length)
    assert_equal(false, @history.visited?(page))
    assert_equal(false, @history.visited?(page2))
    assert_nil(@history.pop)
  end

  def test_max_size
    @history  = WWW::Mechanize::History.new(10)
    1.upto(20) do |i|
      page = @agent.get('http://localhost/index.html')
      @history.push page
      assert_equal(true, @history.visited?(page))
      if i < 10
        assert_equal(i, @history.length)
      else
        assert_equal(10, @history.length)
      end
    end

    @history.clear
    @history.max_size = 5
    1.upto(20) do |i|
      page = @agent.get('http://localhost/index.html')
      @history.push page
      assert_equal(true, @history.visited?(page))
      if i < 5
        assert_equal(i, @history.length)
      else
        assert_equal(5, @history.length)
      end
    end

    @history.max_size = 0
    1.upto(20) do |i|
      page = @agent.get('http://localhost/index.html')
      @history.push page
      assert_equal(false, @history.visited?(page))
      assert_equal(0, @history.length)
    end
  end

  def test_no_slash
    page = @agent.get('http://localhost')

    node = Struct.new(:href, :inner_text).new('http://localhost/', 'blah')
    link = WWW::Mechanize::Page::Link.new(node, nil, nil)
    assert(@agent.visited?(link))

    node = Struct.new(:href, :inner_text).new('http://localhost', 'blah')
    link = WWW::Mechanize::Page::Link.new(node, nil, nil)
    assert(@agent.visited?(link))
  end

  def test_with_slash
    page = @agent.get('http://localhost/')

    node = Struct.new(:href, :inner_text).new('http://localhost/', 'blah')
    link = WWW::Mechanize::Page::Link.new(node, nil, nil)
    assert(@agent.visited?(link))

    node = Struct.new(:href, :inner_text).new('http://localhost', 'blah')
    link = WWW::Mechanize::Page::Link.new(node, nil, nil)
    assert(@agent.visited?(link))
  end

  def test_clear
    page = nil
    20.times { @history.push(page = @agent.get('http://localhost/index.html')) }
    assert_equal(20, @history.length)
    assert_equal(true, @history.visited?(page))
    @history.clear
    assert_equal(0, @history.length)
    assert_equal(false, @history.visited?(page))
  end
end
