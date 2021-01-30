require 'mechanize/test_case'

class TestMechanizeFileResponse < Mechanize::TestCase
  def test_content_type
    Tempfile.open %w[pi .nothtml] do |tempfile|
      res = Mechanize::FileResponse.new tempfile.path
      assert_nil res['content-type']
    end

    Tempfile.open %w[pi .xhtml] do |tempfile|
      res = Mechanize::FileResponse.new tempfile.path
      assert_equal 'text/html', res['content-type']
    end

    Tempfile.open %w[pi .html] do |tempfile|
      res = Mechanize::FileResponse.new tempfile.path
      assert_equal 'text/html', res['Content-Type']
    end
  end

  def test_read_body
    Tempfile.open %w[pi .html] do |tempfile|
      tempfile.write("asdfasdfasdf")
      tempfile.close

      res = Mechanize::FileResponse.new(tempfile.path)
      res.read_body do |input|
        assert_equal("asdfasdfasdf", input)
      end
    end
  end

  def test_read_body_does_not_allow_command_injection
    in_tmpdir do
      FileUtils.touch('| ruby -rfileutils -e \'FileUtils.touch("vul.txt")\'')
      res = Mechanize::FileResponse.new('| ruby -rfileutils -e \'FileUtils.touch("vul.txt")\'')
      res.read_body { |_| }
      refute_operator(File, :exist?, "vul.txt")
    end
  end
end
