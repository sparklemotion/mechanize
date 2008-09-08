module WWW
  class Mechanize
    class Chain
      class ParameterResolver
        include WWW::Handler

        def handle(ctx, params)
          parameters  = params[:params]
          uri         = params[:uri]
          if params[:verb] == :get
            if parameters.length > 0
              uri.query ||= ''
              uri.query << '&' if uri.query.length > 0
              uri.query << Util.build_query_string(parameters)
            end
            params[:params] = []
          end
          super
        end
      end
    end
  end
end
