# frozen_string_literal: true
##
# Wrapper to make a file URI work like an http URI

class Mechanize::FileConnection

  @instance = nil

  def self.new *a
    @instance ||= super
  end

  def request uri, request
    file_path = uri.select(:host, :path)
                  .select { |part| part && (part.length > 0) }
                  .join(":")
    yield Mechanize::FileResponse.new(Mechanize::Util.uri_unescape(file_path))
  end
end
