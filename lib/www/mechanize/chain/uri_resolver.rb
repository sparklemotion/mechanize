module WWW
  class Mechanize
    class Chain
      class URIResolver
        include WWW::Handler

        def initialize(scheme_handlers)
          @scheme_handlers = scheme_handlers
        end

        def handle(ctx, params)
          raise ArgumentError.new('uri must be specified') unless params[:uri]
          params[:uri] = params[:uri].dup if params[:uri].is_a?(URI)
          uri     = params[:uri]
          referer = params[:referer]
          unless uri.is_a?(URI)
            uri = uri.to_s.strip.gsub(/[^#{0.chr}-#{126.chr}]/) { |match|
              if RUBY_VERSION >= "1.9.0"
                CGI.escape(match)
              else
                sprintf('%%%X', match.unpack($KCODE == 'UTF8' ? 'U' : 'c')[0])
              end
            }

            escaped_uri = Util.html_unescape(
              uri.split(/(?:%[0-9A-Fa-f]{2})+|#/).zip(
                uri.scan(/(?:%[0-9A-Fa-f]{2})+|#/)
              ).map { |x,y|
                "#{URI.escape(x)}#{y}"
              }.join('')
            )

            begin
              uri = URI.parse(escaped_uri)
            rescue
              uri = URI.parse(URI.escape(escaped_uri))
            end

          end
          uri = @scheme_handlers[
            uri.relative? ? 'relative' : uri.scheme.downcase
          ].call(uri, params[:referer])

          if params[:referer] && params[:referer].uri
            if uri.path.length == 0 && uri.relative?
              uri.path = params[:referer].uri.path
            end
          end

          uri.path = '/' if uri.path.length == 0

          if uri.relative?
            raise 'need absolute URL' unless referer && referer.uri
            base = nil
            if referer.respond_to?(:bases) && referer.parser
              base = referer.bases.last
            end

            uri = ((base && base.uri && base.uri.absolute?) ?
                    base.uri :
                    referer.uri) + uri
            uri = referer.uri + uri
            # Strip initial "/.." bits from the path
            uri.path.sub!(/^(\/\.\.)+(?=\/)/, '')
          end

          unless ['http', 'https', 'file'].include?(uri.scheme.downcase)
            raise "unsupported scheme: #{uri.scheme}"
          end
          params[:uri] = uri

          super
        end
      end
    end
  end
end
