module WWW
  class Mechanize
    class Chain
      class HeaderResolver
        include WWW::Handler
        def initialize(keep_alive, keep_alive_time, cookie_jar, user_agent, headers)
          @keep_alive = keep_alive
          @keep_alive_time = keep_alive_time
          @cookie_jar = cookie_jar
          @user_agent = user_agent
          @headers = headers
        end

        def handle(ctx, params)
          uri = params[:uri]
          referer = params[:referer]
          request = params[:request]

          if @keep_alive
            request['Connection'] = 'keep-alive'
            request['Keep-Alive'] = @keep_alive_time.to_s
          else
            request['Connection'] = 'close'
          end
          request['Accept-Encoding'] = 'gzip,identity'
          request['Accept-Language'] = 'en-us,en;q=0.5'
          host = "#{uri.host}#{[80, 443].include?(uri.port.to_i) ? '' : ':' + uri.port.to_s}"
          request['Host'] = host
          request['Accept-Charset'] = 'ISO-8859-1,utf-8;q=0.7,*;q=0.7'
  
          unless @cookie_jar.empty?(uri)
            cookies = @cookie_jar.cookies(uri)
            cookie = cookies.length > 0 ? cookies.join("; ") : nil
            request.add_field('Cookie', cookie)
          end
  
          # Add Referer header to request
          if referer && referer.uri
            request['Referer'] = referer.uri.to_s
          end
  
          # Add User-Agent header to request
          request['User-Agent'] = @user_agent if @user_agent 

          @headers.each do |k,v|
            request[k] = v
          end if request
          super
        end
      end
    end
  end
end
