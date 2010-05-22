class Mechanize
  class Chain
    class ResponseHeaderHandler
      include Mechanize::Handler

      def initialize(cookie_jar)
        @cookie_jar = cookie_jar
      end

      def handle(ctx, params)
        response = params[:response]
        uri = params[:uri]
        page = params[:page]

        if page.is_a?(Page) && page.body =~ /Set-Cookie/n
          page.search('//head/meta[@http-equiv="Set-Cookie"]').each do |meta|
            Cookie::parse(uri, meta['content']) { |c|
              Mechanize.log.debug("saved cookie: #{c}") if Mechanize.log
              @cookie_jar.add(uri, c)
            }
          end
        end

        (response.get_fields('Set-Cookie')||[]).each do |cookie|
          Cookie::parse(uri, cookie) { |c|
            Mechanize.log.debug("saved cookie: #{c}") if Mechanize.log
            @cookie_jar.add(uri, c)
          }
        end
        super
      end
    end
  end
end
