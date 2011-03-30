class Mechanize::Chain::CustomHeaders
  include Mechanize::Handler

  def handle(ctx, params)
    request = params[:request]
    params[:headers].each do |k,v|
      case k
      when :etag              then request["ETag"] = v
      when :if_modified_since then request["If-Modified-Since"] = v
      when Symbol then
        raise ArgumentError, "unknown header symbol #{k}"
      else
        request[k] = v
      end
    end
    super
  end
end
