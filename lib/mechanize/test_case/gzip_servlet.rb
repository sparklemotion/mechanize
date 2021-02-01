require 'stringio'
require 'zlib'

class GzipServlet < WEBrick::HTTPServlet::AbstractServlet

  TEST_DIR = File.expand_path '../../../../test', __FILE__

  def do_GET(req, res)
    if req['Accept-Encoding'] !~ /gzip/ then
      res.code = 400
      res.body = 'Content-Encoding: gzip is not supported by your user-agent'
      return
    end

    if name = req.query['file'] then
      ::File.open("#{TEST_DIR}/htdocs/#{name}") do |io|
        string = String.new
        zipped = StringIO.new string, 'w'
        Zlib::GzipWriter.wrap zipped do |gz|
          gz.write io.read
        end
        res.body = string
      end
    else
      res.body = String.new
    end

    res['Content-Encoding'] = req['X-ResponseContentEncoding'] || 'gzip'
    res['Content-Type'] = "text/html"
  end
end

