require 'sinatra'
require 'net/http'
set :server, :puma


get '/hello' do
  uri = URI("https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=APPID&secret=APPSECRET")
  str = Net::HTTP.get(uri)
  #result = "HTTP/1.1 200 OK\r\n\r\n#{str}\r\n"
  str
end