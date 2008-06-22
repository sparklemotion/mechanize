module Net
  class HTTP
    alias :old_keep_alive? :keep_alive?
    def keep_alive?(req, res)
      return false if /close/i =~ req['connection'].to_s
      return false if @seems_1_0_server
      return false if /close/i      =~ res['connection'].to_s
      return true  if /keep-alive/i =~ res['connection'].to_s
      return false if /close/i      =~ res['proxy-connection'].to_s
      return true  if /keep-alive/i =~ res['proxy-connection'].to_s
      (@curr_http_version == '1.1')
    end
  end
end

# Monkey patch for ruby 1.8.4
unless RUBY_VERSION > "1.8.4"
module Net # :nodoc:
  class HTTPResponse # :nodoc:
    CODE_TO_OBJ['500'] = HTTPInternalServerError
  end
end
else
module WWW
  class Mechanize
    class Form
      alias :inspect  :pretty_inspect
    end
    class Page
      alias :inspect  :pretty_inspect
      class Link
        alias :inspect  :pretty_inspect
      end
    end
  end
end
end
