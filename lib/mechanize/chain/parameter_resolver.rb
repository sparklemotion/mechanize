class Mechanize
  class Chain
    class ParameterResolver
      include Mechanize::Handler

      def handle(ctx, params)
        parameters  = params[:params]
        uri         = params[:uri]
        case params[:verb]
        when :head, :get, :delete, :trace
          if parameters and parameters.length > 0
            uri.query ||= ''
            uri.query << '&' if uri.query.length > 0
            uri.query << Util.build_query_string(parameters)
          end
          params[:params] = nil
        end
        super
      end
    end
  end
end
