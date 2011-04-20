require "helper"

class TestHistory < Test::Unit::TestCase

  Node = Struct.new :href, :inner_text

  def setup
    @mech    = Mechanize.new
    @history = Mechanize::History.new
    @uri = URI 'http://example'
  end

  def test_initialize
    assert_equal 0, @history.length
  end

  def test_push
    response = { 'content-type' => 'text/html' }
    page = Mechanize::Page.new @uri, response, '', 200, @mech

    obj = @history.push page

    assert_same @history, obj
    assert_equal 1, @history.length
    assert @history.visited? @uri

    page = Mechanize::Page.new @uri + '/a', response, '', 200, @mech

    @history.push page

    assert_equal 2, @history.length
  end

  def test_push_uri
    obj = @history.push :page, @uri

    assert_same @history, obj
    assert_equal 1, @history.length

    assert @history.visited? @uri

    @history.push :page2, @uri

    assert_equal 2, @history.length
  end

  def test_shift
    assert_nil @history.shift

    @history.push(:page1, @uri)
    @history.push(:page2, @uri + '/a')

    page = @history.shift

    assert_equal :page1, page
    assert_equal 1, @history.length
    assert !@history.visited?(@uri)

    @history.shift

    assert_equal 0, @history.length
  end

  def test_pop
    @history.push(:page, @uri)

    assert_equal(:page, @history.pop)
    assert_equal 0, @history.length
    assert !@history.visited?(@uri)

    assert_nil @history.pop
  end

  def test_max_size
    @history = Mechanize::History.new 2

    1.upto(3) do |i|
      @history.push :page, @uri

      if i >= 2
        assert_equal 2, @history.length
      else
        assert_equal i, @history.length
      end
    end
  end

  def test_visited_eh
    @mech.get('http://localhost/')

    node = Struct.new(:href, :inner_text).new('http://localhost/', 'blah')
    link = Mechanize::Page::Link.new(node, nil, nil)
    assert(@mech.visited?(link))

    node = Struct.new(:href, :inner_text).new('http://localhost', 'blah')
    link = Mechanize::Page::Link.new(node, nil, nil)
    assert(@mech.visited?(link))
  end

  def test_visited_eh_no_slash
    slash    = URI 'http://example/'
    no_slash = URI 'http://example'

    @history.push :page, slash

    assert @history.visited?(slash),    'slash'
    assert @history.visited?(no_slash), 'no slash'
  end

  def test_clear
    @history.push :page, @uri

    @history.clear

    assert_equal 0, @history.length
    assert !@history.visited?(@uri)
  end
end
