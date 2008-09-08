require 'www/mechanize/chain/handler'
require 'www/mechanize/chain/uri_resolver'
require 'www/mechanize/chain/parameter_resolver'
require 'www/mechanize/chain/request_resolver'
require 'www/mechanize/chain/custom_headers'
require 'www/mechanize/chain/connection_resolver'
require 'www/mechanize/chain/ssl_resolver'
require 'www/mechanize/chain/pre_connect_hook'
require 'www/mechanize/chain/auth_headers'
require 'www/mechanize/chain/header_resolver'
require 'www/mechanize/chain/response_body_parser'
require 'www/mechanize/chain/response_header_handler'
require 'www/mechanize/chain/response_reader'
require 'www/mechanize/chain/body_decoding_handler'

module WWW
  class Mechanize
    class Chain
      def initialize(list)
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
  end
end
