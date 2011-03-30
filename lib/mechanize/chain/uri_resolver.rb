class Mechanize::Chain::URIResolver
  include Mechanize::Handler

  def initialize(resolver)
    @resolver = resolver
  end

  def handle(ctx, params)
    raise ArgumentError.new('uri must be specified') unless params[:uri]

    params[:uri] = @resolver.resolve params[:uri], params[:referer]

    super
  end

end

