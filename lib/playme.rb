$LOAD_PATH.unshift(__dir__)
require 'core/base'
require 'benchmark'
require 'net/http'

app = proc do |request|

  #str = HTTP.get(URI("http://www.baidu.com"))
  # url = request['Url']
  if request['Url'] == '/'
    uri = URI("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=APPID&secret=APPSECRET")
    str = Net::HTTP.get(uri)
    "HTTP/1.1 200 OK\r\n\r\n#{str}\r\n"
  else
    "HTTP/1.1 200 OK\r\n\r\nIt's me\r\n"
  end

end

server = PlayMe::Base.new(app)
server.run!
