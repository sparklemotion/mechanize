require "socksify"
require 'socksify/http'

class Mechanize::HTTP::Agent

  public
  def set_socks(addr, port)
    set_http unless @http
    class << @http
      attr_accessor :socks_addr, :socks_port
 
      def http_class
        Net::HTTP.SOCKSProxy(socks_addr, socks_port)
      end
    end
    @http.socks_addr = addr
    @http.socks_port = port
  end

end
