require 'rb_thread_pool'
require 'puma'
require 'socket'

require 'core/client'

module PlayMe

  class RegisterFull < Exception
  end

  class Reactor
    def initialize(app, config={})
      @working_thread_pool = RBThreadPool::Base.new

      @register_queue = Queue.new # store regist io
      @response_queue = Queue.new # store response io
      @alive_pool = [] # only reactor allow operate in this array
      @register_limit = 200
      @operate_count = 100 # how many times reactor operate in one section
      @pending = []
      @alive_limit = 1000
      @status = true

      @app = app

      @playme_blk = proc do |client|
        @app.call(client)
        # done with client actions
        @response_queue.push(client)
      end
    end

    def regist(io)
      raise RegisterFull if @register_queue.size >= @register_limit
      @register_queue.push(io)
    end

    # def done_action(client)
    #   @response_queue.push(client)
    # end

    def run!
      # reactor running
    end

    private

    def reactor_run!
      condi = @status
      pendings = @pending
      while condi
        # first to check pending pool
        op_pending_client(pendings)

        # second to regist new io to be client
        # if it ready immediately, in this step will set it in thread immediately
        # otherwise will put in pending pool arr
        op_regist_io(@operate_count)



      end
    end


    def op_response_client(op)
      responses = @response_queue.pop
      op.times do
        client = responses.pop
        next unless client.ready_to_close?
        client.close

        # stub not finish yet <----
      end
    end


    def op_regist_io(op)
      op.times do
        io = @register_queue.pop(true)
        break unless dispatch_io(io)
      end
    end

    def op_pending_client(pendings)
      return if pendings.empty?
      pendings.times do |idx|
        next unless pendings[idx].ready_to_operate?
        dispatch_to_thread do
          @playme_blk.call(pendings[idx])
        end
        pendings[idx] = nil
      end
      pendings.compact! # remove nil in pending arr
    end

    def op_set_pending_client(client)
      @pending << client
    end

    def dispatch_io(io)
      return false if io.nil?
      client = Client.new(io)
      if client.ready_to_operate?
        dispatch_to_thread do
          @playme_blk.call(client)
        end
      else
        op_set_pending_client(client)
      end
      true
    end

    def dispatch_to_thread(&blk)
      @working_thread_pool.add(&blk)
    end

  end
end