class Mechanize
  class Chain
    class HeaderResolver
      include Mechanize::Handler
      def initialize(cookie_jar, user_agent, gzip_enabled, headers)
        @cookie_jar = cookie_jar
        @user_agent = user_agent
        @gzip_enabled = gzip_enabled
        @headers = headers
      end

      def handle(ctx, params)
        uri = params[:uri]
        referer = params[:referer]
        request = params[:request]

        if @gzip_enabled
          request['Accept-Encoding'] = 'gzip,identity'
        else
          request['Accept-Encoding'] = 'identity'
        end
        request['Accept-Language'] = 'en-us,en;q=0.5'
        host = "#{uri.host}#{[80, 443].include?(uri.port.to_i) ? '' : ':' + uri.port.to_s}"
        request['Host'] = host
        request['Accept-Charset'] = 'ISO-8859-1,utf-8;q=0.7,*;q=0.7'

        unless @cookie_jar.empty?(uri)
          cookies = @cookie_jar.cookies(uri)
          cookie = cookies.length > 0 ? cookies.join("; ") : nil
          request.add_field('Cookie', cookie)
        end

        # Add Referer header to request except https => http
        if referer && referer.uri && (!(URI::HTTPS === referer.uri) or URI::HTTPS === uri)
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
