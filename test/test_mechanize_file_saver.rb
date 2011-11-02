require 'mechanize/test_case'

class TestMechanizeFileSaver < Mechanize::TestCase

  def setup
    super

    @url = URI 'http://example'
  end

  def test_initialize_long_path
    @url += '/one/two/'

    in_tmpdir do
      fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200

      assert_equal 'example/one/two/index.html', fs.filename
    end
  end

  def test_initialize_long_path_file
    @url += '/one/two/foo.html'

    in_tmpdir do
      fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200

      assert_equal 'example/one/two/foo.html', fs.filename
    end
  end

  def test_initialize_multi_slash
    @url += '///foo.html'

    fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200
    assert_equal('example/foo.html', fs.filename)
  end

  def test_initialize_no_path
    in_tmpdir do
      fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200
      assert_equal 'example/index.html', fs.filename
    end
  end

  def test_initialize_slash
    @url += '/'

    in_tmpdir do
      fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200
      assert_equal 'example/index.html', fs.filename
    end
  end

  def test_initialize_slash_file
    @url += '/foo.html'

    in_tmpdir do
      fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200
      assert_equal 'example/foo.html', fs.filename
    end
  end

  def test_initialize_query
    @url += '/?id=5'

    in_tmpdir do
      fs = Mechanize::FileSaver.new @url, nil, 'hello world', 200
      assert_equal 'example/index.html?id=5', fs.filename
    end
  end

end

