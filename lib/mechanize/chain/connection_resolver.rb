class Mechanize
  class Chain
    class ConnectionResolver
      include Mechanize::Handler

      def handle(ctx, params)
        uri = params[:uri]
        http_obj = nil

        case uri.scheme.downcase
        when 'http', 'https' then
          http_obj = ctx.http
        when 'file' then
          http_obj = Object.new
          class << http_obj
            def request(uri, request)
              yield FileResponse.new(CGI.unescape(uri.path))
            end
          end
        end

        params[:connection] = http_obj

        super
      end
    end
  end
end
