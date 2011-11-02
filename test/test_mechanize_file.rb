require 'mechanize/test_case'

class TestMechanizeFile < Mechanize::TestCase

  def setup
    @parser = Mechanize::File
  end

  def test_save
    uri = URI 'http://example/name.html'
    page = Mechanize::File.new uri, nil, '0123456789'

    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        page.save 'test.html'

        assert_equal '0123456789', File.read('test.html')
      end
    end
  end

  def test_save_default
    uri = URI 'http://example/test.html'
    page = Mechanize::File.new uri, nil, ''

    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        page.save

        assert File.exist? 'test.html'

        page.save

        assert File.exist? 'test.html.1'

        page.save

        assert File.exist? 'test.html.2'
      end
    end
  end

  def test_save_default_dots
    uri = URI 'http://localhost/../test.html'
    page = Mechanize::File.new uri, nil, ''

    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        page.save
        assert File.exist? 'test.html'

        page.save
        assert File.exist? 'test.html.1'
      end
    end
  end

end

