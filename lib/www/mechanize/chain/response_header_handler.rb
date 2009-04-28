module WWW
  class Mechanize
    class Chain
      class ResponseHeaderHandler
        include WWW::Handler

        def initialize(cookie_jar, connection_cache)
          @cookie_jar = cookie_jar
          @connection_cache = connection_cache
        end

        def handle(ctx, params)
          response = params[:response]
          uri = params[:uri]
          page = params[:page]
          cache_obj = (@connection_cache["#{uri.host}:#{uri.port}"] ||= {
            :connection         => nil,
            :keep_alive_options => {},
          })

          # If the server sends back keep alive options, save them
          if keep_alive_info = response['keep-alive']
            keep_alive_info.split(/,\s*/).each do |option|
              k, v = option.split(/=/)
              cache_obj[:keep_alive_options] ||= {}
              cache_obj[:keep_alive_options][k.intern] = v
            end
          end

          if page.is_a?(Page) && page.body =~ /Set-Cookie/n
            page.search('//meta[@http-equiv="Set-Cookie"]').each do |meta|
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
end
