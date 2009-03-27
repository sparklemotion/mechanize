module WWW
  class Mechanize
    class Chain
      class CustomHeaders
        include WWW::Handler

        def handle(ctx, params)
          request = params[:request]
          params[:headers].each do |k,v|
            case k
            when :etag then request["ETag"] = v
            when :if_modified_since then request["If-Modified-Since"] = v
            else
              raise ArgumentError.new("unknown header symbol #{k}") if k.is_a? Symbol
              request[k] = v
            end
          end
          super
        end
      end
    end
  end
end
