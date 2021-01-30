class VerbServlet < WEBrick::HTTPServlet::AbstractServlet
  %w[HEAD GET POST PUT DELETE].each do |verb|
    define_method "do_#{verb}" do |req, res|
      res.header['X-Request-Method'] = verb
      res.body = verb
    end
  end
end

