require 'socket'
require 'core/reactor'

module PlayMe
  class Base
    def initialize(app, config = {})
      @listener = TCPServer.new('127.0.0.1', 4455)
      @reactor = Reactor.new(app, config)
      @fork_pool = []
      #@parser = HttpParser.new
    end

    def run!
      4.times do
        Process.fork do
          start
        end
      end
      Process.waitall
    end

    def start
      @reactor.run!
      puts "PlayMe start..."
      #sleep(1)
      while true
        io = @listener.accept
        $stdout.write("#{io.peeraddr.last} connecting \r\n")
        @reactor.regist io
      end
    end
  end
end