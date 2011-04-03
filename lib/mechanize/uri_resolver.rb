class Mechanize::URIResolver

  attr_reader :scheme_handlers

  def initialize
    @scheme_handlers = Hash.new { |h, scheme|
      h[scheme] = lambda { |link, page|
        raise Mechanize::UnsupportedSchemeError, scheme
      }
    }

    @scheme_handlers['http']      = lambda { |link, page| link }
    @scheme_handlers['https']     = @scheme_handlers['http']
    @scheme_handlers['relative']  = @scheme_handlers['http']
    @scheme_handlers['file']      = @scheme_handlers['http']
  end

  def resolve uri, referer = nil
    uri = uri.dup if uri.is_a?(URI)

    unless uri.is_a?(URI)
      uri = uri.to_s.strip.gsub(/[^#{0.chr}-#{126.chr}]/o) { |match|
        if RUBY_VERSION >= "1.9.0"
          CGI.escape(match)
        else
          sprintf('%%%X', match.unpack($KCODE == 'UTF8' ? 'U' : 'C')[0])
        end
      }

      unescaped = uri.split(/(?:%[0-9A-Fa-f]{2})+|#/)
      escaped   = uri.scan(/(?:%[0-9A-Fa-f]{2})+|#/)

      escaped_uri = Mechanize::Util.html_unescape(
        unescaped.zip(escaped).map { |x,y|
          "#{WEBrick::HTTPUtils.escape(x)}#{y}"
        }.join('')
      )

      begin
        uri = URI.parse(escaped_uri)
      rescue
        uri = URI.parse(WEBrick::HTTPUtils.escape(escaped_uri))
      end
    end

    scheme = uri.relative? ? 'relative' : uri.scheme.downcase
    uri = @scheme_handlers[scheme].call(uri, referer)

    if referer && referer.uri
      if uri.path.length == 0 && uri.relative?
        uri.path = referer.uri.path
      end
    end

    uri.path = '/' if uri.path.length == 0

    if uri.relative?
      raise ArgumentError, "absolute URL needed (not #{uri})" unless
        referer && referer.uri

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
      raise ArgumentError, "unsupported scheme: #{uri.scheme}"
    end

    uri
  end

end

