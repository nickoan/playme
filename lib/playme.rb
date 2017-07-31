$LOAD_PATH.unshift(__dir__)
require 'core/base'
require 'benchmark'
require 'net/http'

app = proc do |request|
  if request['Url'] == '/'
    uri = URI("https://zhidao.baidu.com/question/586135862.html")
    str = Net::HTTP.get(uri)
    [200, {'Content-Type' => 'text/html;charset=utf-8'}, str]
  else
    [500, {'Content-Type' => 'text/html;charset=utf-8'}, 'hello world']
  end

end

server = PlayMe::Base.new(app)
server.run!
