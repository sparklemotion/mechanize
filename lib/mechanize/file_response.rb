##
# Fake response for dealing with file:/// requests

class Mechanize::FileResponse
  def initialize(file_path)
    @file_path = file_path
  end

  def read_body
    if File.exist?(@file_path)
      if directory?
        yield dir_body
      else
        open @file_path, 'rb' do |io|
          yield io.read
        end
      end
    else
      yield ''
    end
  end

  def code
    File.exist?(@file_path) ? 200 : 400
  end

  def content_length
    return dir_body.length if directory?
    File.exist?(@file_path) ? File.stat(@file_path).size : 0
  end

  def each_header; end

  def [](key)
    return nil unless key.downcase == 'content-type'
    return 'text/html' if directory?
    return 'text/html' if ['.html', '.xhtml'].any? { |extn|
      @file_path =~ /#{extn}$/
    }
    nil
  end

  def each
  end

  def get_fields(key)
    []
  end

  def http_version
    '0'
  end

  def message
    File.exist?(@file_path) ? 'OK' : 'Bad Request'
  end

  private

  def dir_body
    body = %w[<html><body>]
    body.concat Dir[File.join(@file_path, '*')].map { |f|
      "<a href=\"file://#{f}\">#{File.basename(f)}</a>"
    }
    body << %w[</body></html>]

    body = body.join "\n"
    body.force_encoding Encoding::BINARY if body.respond_to? :force_encoding
    body
  end

  def directory?
    File.directory?(@file_path)
  end
end

