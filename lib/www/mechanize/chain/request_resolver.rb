module WWW
  class Mechanize
    class Chain
      class RequestResolver
        include WWW::Handler

        def handle(ctx, params)
          uri = params[:uri]
          if %w{ http https }.include?(uri.scheme.downcase)
            klass = Net::HTTP.const_get(params[:verb].to_s.capitalize)
            params[:request] ||= klass.new(uri.request_uri)
          end

          if %w{ file }.include?(uri.scheme.downcase)
            o = Struct.new(:uri).new(uri)
            class << o
              def add_field(*args); end
              alias :[]= :add_field
              def path
                uri.path
              end
              def each_header; end
            end
            params[:request] ||= o
          end

          super
        end
      end
    end
  end
end
