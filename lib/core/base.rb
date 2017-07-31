require 'socket'
require 'core/reactor'

module PlayMe

  class Base

    def initialize(app, config = {})
      @config = config.dup
      @listener = TCPServer.new(@config[:host] || '127.0.0.1',
                                @config[:port] || 4455)
      @reactor = Reactor.new(app, config)
      @fork_pool = []
      @works_amount = config[:works] || 1
      @condition = true
    end

    def run!

      message = "PlayMe start...\r\n"
      message << "Address: #{@config[:host] || '127.0.0.1'}\r\n"
      message << "Port: #{@config[:port] || 4455}\r\n"
      $stdout.write message

      if @works_amount <= 1 or @config[:single] == true
        start
      else
        @works_amount.times do
          @fork_pool << Process.fork do
            start
          end
        end
        begin
          Process.waitall
        rescue Interrupt
          @fork_pool.each do |pid|
            Process.kill('TERM', pid)
          end
          sleep(2)
          puts 'Master quiting'
          Process.exit
        end
      end
    end


    def start
      @reactor.run!
      #Signal.trap('TERM') { @condition = false; puts 'condition turn off' }
      # at_exit {}
      while @condition
        begin
          io = @listener.accept
          @reactor.regist io
        rescue Interrupt
          puts "#{Process.pid} attach with Interrupt\r\n"
          break
        end
      end
      Process.exit!
    end

  end
end