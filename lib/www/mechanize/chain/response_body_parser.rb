module WWW
  class Mechanize
    class Chain
      class ResponseBodyParser
        include WWW::Handler

        def initialize(pluggable_parser, watch_for_set)
          @pluggable_parser = pluggable_parser
          @watch_for_set = watch_for_set
        end

        def handle(ctx, params)
          response = params[:response]
          response_body = params[:response_body]
          uri = params[:uri]

          content_type = nil
          unless response['Content-Type'].nil?
            data = response['Content-Type'].match(/^([^;]*)/)
            content_type = data[1].downcase.split(',')[0] unless data.nil?
          end

          # Find our pluggable parser
          params[:page] = @pluggable_parser.parser(content_type).new(
            uri,
            response,
            response_body,
            response.code
          ) { |parser|
            parser.mech = params[:agent] if parser.respond_to? :mech=
            if parser.respond_to?(:watch_for_set=) && @watch_for_set
              parser.watch_for_set = @watch_for_set
            end
          }
          super
        end
      end
    end
  end
end
