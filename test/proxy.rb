# This is a simple proxy that assumes the destination server will
# close the connection after sending data, otherwise it will get blocked
# on reads.

require 'rubygems'
require 'eventmachine'
require 'socket'

module HttpProxy
  include Socket::Constants

  def receive_data(data)
    if data =~ /Host: (.*)$/
      (host, port) = $1.chomp.split(/:/)
      port ||= 80
      socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
      puts port.to_i
      puts host
      sockaddr = Socket.pack_sockaddr_in( port.to_i, host )
      socket.connect(sockaddr)
      socket.write(data)
      results = socket.read
      send_data results
    end
  end
end

EventMachine::run {
  EventMachine::start_server "127.0.0.1", 2001, HttpProxy
}
