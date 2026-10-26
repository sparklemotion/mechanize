# frozen_string_literal: true
require 'mechanize/test_case'

class TestMechanizeFileSaver < Mechanize::TestCase

  def setup
    super

    @uri = URI 'http://example'
    @io = StringIO.new 'hello world'
  end

  def test_initialize
    in_tmpdir do
      Mechanize::FileSaver.new @uri, nil, @io, 200

      assert File.exist? 'example/index.html'
    end
  end

  def test_initialize_uri_dot_segments
    in_tmpdir do
      FileUtils.mkdir 'cwd'
      uri = URI 'http://example/a/../../../outside.html'

      Dir.chdir 'cwd' do
        Mechanize::FileSaver.new uri, nil, @io, 200
      end

      assert_empty saved_files_outside('cwd/example')
      assert File.exist? 'cwd/example/outside.html'
    end
  end

  def test_initialize_uri_dot_segments_after_double_slash
    in_tmpdir do
      FileUtils.mkdir 'cwd'
      uri = URI 'http://example//a/../outside/../example/payload.txt'

      Dir.chdir 'cwd' do
        Mechanize::FileSaver.new uri, nil, @io, 200
      end

      refute File.exist? 'cwd/outside'
      assert File.exist? 'cwd/example/example/payload.txt'
    end
  end

  def test_absolute_redirect_dot_segments
    in_tmpdir do
      mech = Mechanize.new
      mech.pluggable_parser.html = Mechanize::FileSaver

      mech.get 'http://example/redirect', [], nil,
               'X-Location' => 'http://example/relative/../../htdocs/index.html'

      assert_empty saved_files_outside('example')
      assert File.exist? 'example/htdocs/index.html'
    end
  end

  def test_initialize_content_disposition_dot_segment
    in_tmpdir do
      response = { 'content-disposition' => 'attachment; filename=".."' }

      assert_raises Mechanize::Error do
        Mechanize::FileSaver.new @uri, response, @io, 200
      end
    end
  end

  def saved_files_outside directory
    Dir.glob('**/*').select { |path| File.file? path }.reject { |path| path.start_with? "#{directory}/" }
  end

end

