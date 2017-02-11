require "test/unit"
require "fluent/test"
require "fluent/test/helpers"
require "fluent/test/driver/input"

include Fluent::Test::Helpers

def unused_port(num = 1, protocol: :tcp, bind: "0.0.0.0")
  case protocol
  when :tcp
    unused_port_tcp(num)
  when :udp
    unused_port_udp(num, bind: bind)
  else
    raise ArgumentError, "unknown protocol: #{protocol}"
  end
end

def unused_port_tcp(num = 1)
  ports = []
  sockets = []
  num.times do
    s = TCPServer.open(0)
    sockets << s
    ports << s.addr[1]
  end
  sockets.each{|s| s.close }
  if num == 1
    return ports.first
  else
    return *ports
  end
end

PORT_RANGE_AVAILABLE = (1024...65535)

def unused_port_udp(num = 1, bind: "0.0.0.0")
  family = IPAddr.new(IPSocket.getaddress(bind)).ipv4? ? ::Socket::AF_INET : ::Socket::AF_INET6
  ports = []
  sockets = []
  while ports.size < num
    port = rand(PORT_RANGE_AVAILABLE)
    u = UDPSocket.new(family)
    if (u.bind(bind, port) rescue nil)
      ports << port
      sockets << u
    else
      u.close
    end
  end
  sockets.each{|s| s.close }
  if num == 1
    return ports.first
  else
    return *ports
  end
end
