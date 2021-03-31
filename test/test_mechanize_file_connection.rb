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

    assert_equal File.read(__FILE__), body.gsub(/\r\n/, "\n")
  end

  def test_request_on_uri_with_windows_drive
    uri_string = "file://C:/path/to/file.html"
    expected_file_path = "C:/path/to/file.html"

    uri = URI.parse(uri_string)
    conn = Mechanize::FileConnection.new

    called = false
    yielded_file_path = nil
    conn.request(uri, nil) do |response|
      called = true
      yielded_file_path = response.file_path
    end

    assert(called)
    assert_equal(expected_file_path, yielded_file_path)
  end
end
