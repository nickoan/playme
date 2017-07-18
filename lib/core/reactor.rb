require 'rb_thread_pool'
require 'socket'

require 'core/client'

module PlayMe

  class RegisterFull < Exception
  end

  class Reactor

    attr_reader :pending, :writing, :alive_pool, :reactor_running

    attr_accessor :status, :app, :playme_blk

    # in process, a lot of function and code logic are not added in

    # my plan is try not using mutex, most non block operation will run in reactor
    # some other will using ruby queue and put proc into queue, let them run in thread pool


    # app is a custom class or proc that able to call, just like rack apps
    # config is the configure for this server, currently not add in anythings yet

    def initialize(app, config = {})

      @configure = config.dup
      @working_thread_pool = RBThreadPool::Base.new(config)

      @register_queue = Queue.new # store regist io
      @response_queue = Queue.new # store response io

      @register_limit = 200
      @operate_count = 100 # how many times reactor operate in one section

      @pending = []

      @writing = []

      @alive_pool = [] # only reactor allow operate in this array
      @alive_limit = 1000
      @status = true

      @app = app

      @playme_blk = proc do |client|
        @app.call(client)
        # done with client actions
        @response_queue.push(client)
      end

      @reactor_thread = nil
      @reactor_running = false
    end

    def regist(io)
      raise RegisterFull if @register_queue.size >= @register_limit
      @register_queue.push(io)
    end



    # Reactor start here
    def run!
      return false if @reactor_running
      @reactor_running = true
      # reactor running
      @reactor_thread = Thread.fork do
        th_current = Thread.current
        th_current.name = "PlayMe:Reactor #{Thread.current.to_s}" if Thread.respond_to?(:name=)
        th_current.current.priority = 3 # always run reactor first
        th_current.current.abort_on_exception = true
        reactor_run!
      end
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

        # checking writing client io finish yet?
        op_writing_client(@writing)

        # get response from response pool, try writing them, if not finish put in writing arr
        op_response_client(@operate_count)

      end
    end


    def op_response_client(op)
      responses = @response_queue.pop
      current_time = Time.now.to_i
      op.times do
        client = responses.pop
        state = catch :checked do
          checking_client_state(client, current_time)
        end

        case state
          when :timed_out, :ready_close then
            client.close
          when :need_alive then
            @alive_pool << client
          when :not_finish then
            @writing << client
          else
            raise Exception, 'unknown state at op_response_client'
        end
      end
    end


    def op_writing_client(writing)
      return if writing.empty?
      op_time = writing.size
      current_time = Time.now.to_i

      need_compact = false

      op_time.times do |idx|
        client = writing[idx]
        state = catch :checked do
          checking_client_state(client, current_time)
        end

        case state
          when :timed_out, :ready_close then
            client.close
            writing[idx] = nil
            need_compact = true unless need_compact
          when :need_alive then
            raise Exception, 'cannot set alive in writing state'
          when :not_finish then
            next
          else
            raise Exception, 'unknown state at op_response_client'
        end
      end
      writing.compact! if need_compact
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


    def checking_client_state(client, current_time = Time.now.to_i)
      if client.timed_out?(current_time)
        throw :checked, :timed_out
      elsif client.ready_to_close?
        # checking if need keep tcp connection
        if client.need_alive?
          throw :checked, :need_alive
        end
        throw :checked, :ready_close
      end
      :not_finish
    end

  end
end