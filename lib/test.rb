require './playme'

require 'net/http'

app = proc do |request|
  if request['Url'] == '/'
    # uri = URI("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=APPID&secret=APPSECRET")
    # str = Net::HTTP.get(uri)
    [200, {'Content-Type' => 'text/plain', 'Connection' => 'keep-alive'}, '123']
  else
    [200, {'Content-Type' => 'text/html'}, 'hello world']
  end
end

server = PlayMe::Base.new(app, works:3)
server.run!
