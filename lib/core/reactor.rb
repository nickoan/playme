require 'rb_thread_pool'
require 'socket'

module PlayMe

  class RegisterFull < Exception
  end

  class Reactor
    def initialize
      @working_thread_pool = RBThreadPool::Base.new
      @register_queue = Queue.new
      @response_queue = Queue.new
      @register_limit = 200
    end

    def regist(io)
      raise RegisterFull if @register_queue.size >= @register_limit
      @register_queue.push(io)
    end

    def run!
      # reactor running
    end

    private

    def dispatch_io
      io = @register_queue.pop(true)
      # wrap to client later
    end
  end
end