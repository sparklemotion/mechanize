# frozen_string_literal: true
##
# Wrapper to make a file URI work like an http URI

class Mechanize::FileConnection

  @instance = nil

  def self.new *a
    @instance ||= super
  end

  def request uri, request
    file_path = uri.path
    yield Mechanize::FileResponse.new(Mechanize::Util.uri_unescape(file_path))
  end
end
