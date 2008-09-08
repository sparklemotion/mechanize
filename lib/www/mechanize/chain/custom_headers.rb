module WWW
  class Mechanize
    class Chain
      class CustomHeaders
        include WWW::Handler

        def handle(ctx, params)
          request = params[:request]
          params[:headers].each do |k,v|
            case k
            when :etag then request.add_field("ETag", v)
            when :if_modified_since then request.add_field("If-Modified-Since", v)
            else
              raise ArgumentError.new("unknown header symbol #{k}") if k.is_a? Symbol
              request.add_field(k,v)
            end
          end
          super
        end
      end
    end
  end
end
