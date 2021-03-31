require 'mechanize/test_case'

class TestMechanizeFileConnection < Mechanize::TestCase

  def test_request
    file_path = File.expand_path(__FILE__)
    uri = URI.parse "file://#{file_path}"
    conn = Mechanize::FileConnection.new

    body = ''

    conn.request uri, nil do |response|
      assert_equal(file_path, response.file_path)
      response.read_body do |part|
        body << part
      end
    end

    assert_equal File.read(__FILE__), body
  end

end

