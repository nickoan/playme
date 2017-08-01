# playme
a ruby reactor tcp server with multiprocess, able run on windows

currently not support with rack..

still in design...!

basic sample :

```ruby
  
require './playme'

require 'net/http'

app = proc do |request|
  if request['Url'] == '/'
    # uri = URI("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=APPID&secret=APPSECRET")
    # str = Net::HTTP.get(uri)
    [200, {'Content-Type' => 'text/plain'}, '123']
  else
    [200, {'Content-Type' => 'text/html'}, 'hello world']
  end
end

# in here server will fork 3 processes to listen your http request
server = PlayMe::Base.new(app, works:3)

# if you run it on windows or you do not prefer run in multiprocess, then you able 
# remove works config just like this:
# example: 
# server = PlayMe::Base.new(app)

server.run!
```
