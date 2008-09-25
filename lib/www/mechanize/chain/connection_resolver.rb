module WWW
  class Mechanize
    class Chain
      class ConnectionResolver
        include WWW::Handler

        def initialize( connection_cache,
                        keep_alive,
                        proxy_addr,
                        proxy_port,
                        proxy_user,
                        proxy_pass )

          @connection_cache = connection_cache
          @keep_alive = keep_alive
          @proxy_addr = proxy_addr
          @proxy_port = proxy_port
          @proxy_user = proxy_user
          @proxy_pass = proxy_pass
        end

        def handle(ctx, params)
          uri = params[:uri]
          http_obj = nil

          case uri.scheme.downcase
          when 'http', 'https'
            cache_obj = (@connection_cache["#{uri.host}:#{uri.port}"] ||= {
              :connection         => nil,
              :keep_alive_options => {},
            })
            http_obj = cache_obj[:connection]
            if http_obj.nil? || ! http_obj.started?
              http_obj = cache_obj[:connection] =
                  Net::HTTP.new( uri.host,
                          uri.port,
                          @proxy_addr,
                          @proxy_port,
                          @proxy_user,
                          @proxy_pass
                        )
              cache_obj[:keep_alive_options] = {}
            end

            # If we're keeping connections alive and the last request time is too
            # long ago, stop the connection.  Or, if the max requests left is 1,
            # reset the connection.
            if @keep_alive && http_obj.started?
              opts = cache_obj[:keep_alive_options]
              if((opts[:timeout] &&
                 Time.now.to_i - cache_obj[:last_request_time] > opts[:timeout].to_i) ||
                  opts[:max] && opts[:max].to_i == 1)
  
                Mechanize.log.debug('Finishing stale connection') if Mechanize.log
                http_obj.finish
  
              end
            end

            cache_obj[:last_request_time] = Time.now.to_i
          when 'file'
            http_obj = Object.new
            class << http_obj
              def started?; true; end
              def request(request, *args, &block)
                response = FileResponse.new(request.uri.path)
                yield response
              end
            end
          end

          params[:connection] = http_obj
          super
        end
      end
    end
  end
end
