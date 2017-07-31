# require 'socket'
#
#
# server = TCPServer.new('192.168.10.64',4455)
#
#
#
# io = server.accept
#
#
# sleep 2
#
#
# while true
#   message = io.read
#   p message
#   message.write('readed')
# end


require 'faye/websocket'
require 'json'

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :message do |event|
      p event.data
      ws.send({response:'server response'}.to_json)
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    # Normal HTTP request
    [200, {'Content-Type' => 'text/plain'}, ['Hello']]
  end
end



Faye::WebSocket.load_adapter('thin')

thin = Rack::Handler.get('thin')

thin.run(App, :Port => 4567, :Host => '192.168.10.64')