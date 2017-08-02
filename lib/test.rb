require './playme'

require 'net/http'

app = proc do |request|
  if request['Url'] == '/'
    [200, {'Content-Type' => 'text/plain'}, '123']
  else
    [200, {'Content-Type' => 'text/html'}, 'hello world']
  end
end

server = PlayMe::Base.new(app)
server.run!
