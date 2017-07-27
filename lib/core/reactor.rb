require 'rb_thread_pool'
require 'core/http_parser'
require 'core/client'

module PlayMe
  class Reactor
    def initialize(app, config = {})
      @app = app
      @config = config.dup

      # this will using community with threads
      # so we will using ruby queue
      @register = Queue.new
      @responses = Queue.new

      @pending = []
      @writing = []
      @living = []

      @thread_pool = RBThreadPool::Base.new(config)
      @reactor = nil

      @parser = Parser.new

      # when all queue and array empty it will turn false
      # which mean will block reactor
      @condition = false

      @clients = 0
    end


    def run!
      @reactor = Thread.new do
        Thread.abort_on_exception = true
        Thread.current.name = "PlayMe:Reactor #{Thread.current.to_s}" if Thread.respond_to?(:name=)
        Thread.current.priority = 4
        # stub hold
        @thread_pool.start!
        reactor_run_in_th
      end
    end


    def regist(io)
      @register.push ::PlayMe::Client.new(io)
      signal_add_client
    end

    private


    def reactor_run_in_th
      while true
        op_register_client

        op_pending_client

        op_living_client

        op_writing_client

        op_response_client
      end
    end

    private

    def op_living_client
      return if @living.empty?
      @living.size.times do |idx|
        client = @living[idx]
        if client.timeout?
          close_client client
          @living[idx] = nil
          next
        end

        if client.try_read
          run_in_pool(client)
          @living[idx] = nil
        end
      end
      @living.compact!
    end


    def op_writing_client
      return if @writing.empty?
      size = @writing.size
      size.times do |idx|
        client = @writing[idx]

        if client.timeout?
          close_client client
          @writing[idx] = nil
          next
        end

        if client.try_write
          @writing[idx] = nil
        end
      end
      @writing.compact!
    end

    def op_response_client
      return if @responses.empty?
      client = @responses.shift(true)
      if client.try_write
        if client.alive?
          @living << client
          return
        end
        err = catch :error_closed do
          close_client client
          return
        end
        p err.message unless err.nil?
      else
        @writing << client
      end
    end

    def op_pending_client
      return if @pending.empty?
      size = @pending.size

      size.times do |idx|
        client = @pending[idx]

        if client.timeout?
          close_client client
          @pending[idx] = nil
          next
        end

        if client.try_read
          run_in_pool client
          @pending[idx] = nil
        end
      end

      @pending.compact!
    end

    def op_register_client
      return if @register.empty? and @condition
      client = @register.pop(@condition)
      @condition = true unless @conditiongi
      # reset pop to be non block
      return run_in_pool(client) if client.try_read
      @pending << client
    end

    def signal_add_client
      @clients += 1
    end

    def signal_min_client
      @clients -= 1
      if @clients.zero?
        @condition = false
        return
      end
    end

    def close_client(client)
      client.close
      signal_min_client
    end

    def run_in_pool(client)
      request = client.request
      @thread_pool.add do
        env = @parser.execute request
        response, alive = @app.call(env)
        client << response
        client.alive = true if alive
        @responses.push client
      end
    end

  end
end