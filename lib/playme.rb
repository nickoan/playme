$LOAD_PATH.unshift(__dir__)
require 'core/base'
require 'benchmark'


app = proc do |request|
  p request['Method'] + request['Url']
  "HTTP/1.1 200 OK\r\n\r\nHello\r\n"
end

server = PlayMe::Base.new(app)
server.run!