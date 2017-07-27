

app = proc do |request|
  "HTTP/1.1 200 OK\r\n\r\nHello\r\n"
end

server = PlayMe::Base.new(app)
server.run!