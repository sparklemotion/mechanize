module WWW
  class Mechanize
    class Chain
      class HeaderResolver
        include WWW::Handler
        def initialize(keep_alive, keep_alive_time, cookie_jar, user_agent)
          @keep_alive = keep_alive
          @keep_alive_time = keep_alive_time
          @cookie_jar = cookie_jar
          @user_agent = user_agent
        end

        def handle(ctx, params)
          uri = params[:uri]
          referer = params[:referer]
          request = params[:request]

          if @keep_alive
            request.add_field('Connection', 'keep-alive')
            request.add_field('Keep-Alive', @keep_alive_time.to_s)
          else
            request.add_field('Connection', 'close')
          end
          request.add_field('Accept-Encoding', 'gzip,identity')
          request.add_field('Accept-Language', 'en-us,en;q=0.5')
          request.add_field('Host', uri.host)
          request.add_field('Accept-Charset', 'ISO-8859-1,utf-8;q=0.7,*;q=0.7')
  
          unless @cookie_jar.empty?(uri)
            cookies = @cookie_jar.cookies(uri)
            cookie = cookies.length > 0 ? cookies.join("; ") : nil
            request.add_field('Cookie', cookie)
          end
  
          # Add Referer header to request
          unless referer.uri.nil?
            request.add_field('Referer', referer.uri.to_s)
          end
  
          # Add User-Agent header to request
          request.add_field('User-Agent', @user_agent) if @user_agent 
          super
        end
      end
    end
  end
end
