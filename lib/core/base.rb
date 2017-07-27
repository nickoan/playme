require 'socket'
require 'core/reactor'

module PlayMe
  class Base
    def initialize(app, config = {})
      @listener = TCPServer.new('127.0.0.1', 4455)
      @reactor = Reactor.new(app, config)
      #@parser = HttpParser.new
    end

    def run!
      @reactor.run!
      puts "PlayMe start..."
      #sleep(1)
      while true
        io = @listener.accept
        @reactor.regist io
      end
    end
  end
end