$LOAD_PATH.unshift(__dir__)
require 'core/base'

# require 'rack'
# require 'puma'
# require 'rack/handler/thin'
# require 'rack/request'
# require 'rack/server'

app = proc do |request|
  #p request
  "HTTP/1.1 200 OK\r\n\r\nHello\r\n"
end

server = PlayMe::Base.new(app)
# #
server.run!

# str = "GET / HTTP/1.1\r\ncache-control: no-cache\r\nPostman-Token: 7e36d1a2-1bc2-47dc-898f-e7cfa9f2a13c\r\nUser-Agent: PostmanRuntime/3.0.11-hotfix.2\r\nAccept: */*\r\nHost: 127.0.0.1:4455\r\naccept-encoding: gzip, deflate\r\nConnection: keep-alive\r\n\r\n"
#
# request = Rack::Utils
#
#p request


