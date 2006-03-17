require 'webrick'
require 'logger'

class FormTest < WEBrick::HTTPServlet::AbstractServlet
  def do_GET(req, res)
    res.body = "<HTML><body>"
    req.query.each_key { |k|
      res.body << "<a href=\"#\">#{k}:#{req.query[k]}</a><br />"
    }
    res.body << "</body></HTML>"
    res['Content-Type'] = "text/html"
  end

  def do_POST(req, res)
    res.body = "<HTML><body>"
    req.query.each_key { |k|
      res.body << "<a href=\"#\">#{k}:#{req.query[k]}</a><br />"
    }
    res.body << "</body></HTML>"
    res['Content-Type'] = "text/html"
  end
end

