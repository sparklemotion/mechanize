class Mechanize::Chain
  attr_accessor :http

  def self.handle list, request, http = nil
    new(list, http).handle request
  end

  def initialize(list, http = nil)
    @http = http
    @list = list
    @list.each { |l| l.chain = self }
  end

  def handle(request)
    @list.first.handle(self, request)
  end

  def pass(obj, request)
    next_link = @list[@list.index(obj) + 1]
    next_link.handle(self, request) if next_link
  end
end

require 'mechanize/chain/handler'
require 'mechanize/chain/auth_headers'
require 'mechanize/chain/body_decoding_handler'
require 'mechanize/chain/connection_resolver'
require 'mechanize/chain/custom_headers'
require 'mechanize/chain/header_resolver'
require 'mechanize/chain/pre_connect_hook'
require 'mechanize/chain/response_body_parser'
require 'mechanize/chain/response_header_handler'
require 'mechanize/chain/response_reader'
require 'mechanize/chain/ssl_resolver'

