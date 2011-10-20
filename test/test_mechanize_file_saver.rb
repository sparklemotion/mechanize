require 'helper'

class TestMechanizeFileSaver < MiniTest::Unit::TestCase

  def test_initialize_long_path
    url = URI 'http://example.com/one/two/'

    fs = Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/one/two/index.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_initialize_long_path_file
    url = URI 'http://example.com/one/two/foo.html'

    fs = Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/one/two/foo.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_initialize_no_path
    url = URI 'http://example.com'

    fs = Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/index.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_initialize_slash
    url = URI 'http://example.com/'

    fs = Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/index.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

  def test_initialize_slash_file
    url = URI 'http://example.com/foo.html'

    fs = Mechanize::FileSaver.new(url, nil, 'hello world', 200)
    assert_equal('example.com/foo.html', fs.filename)
    FileUtils.rm_rf('example.com')
  end

end

