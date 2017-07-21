require 'rb_thread_pool'


module PlayMe

  class MeReactor
    def initialize(app, config = {})
      @app = app
      @config = config.dup

      @accepts = 100 || @config[:accepts]
      @alives = 1000 || @config[:alives]

      @register = Queue.new
      @responses = Queue.new

      @mutex = Mutex.new
      @pending = []
      @writing = []
      @alive_tcps = []

      config[:limit] = 1000 || config[:limit]
      @thread_pool = RBThreadPool::Base.new(config)

      @condition = true
    end

    private

    def reactor_running_in_thread!
      while @condition

        # check pending array, move it to thread pool to process.
        op_pending_to_th_pool

        op_register_to_pending(100)

        op_response_to_write(100)
      end
    end

    def op_writing_response
      # in process
    end

    def op_response_to_write(num)
      num.times do
        move_response_out_queue
      end
    end

    def op_register_to_pending(num)
      num.times do |idx|
        plain_io = @register.pop(true)
        if plain_io != nil
          client = IoClient.new(plain_io)
          @pending << client
        end
      end
    end


    def op_pending_to_th_pool
      return if @pending.empty?
      @pending.size.times do |idx|
        client = @pending[idx]
        next unless client.try_read?
        result = put_request_in_pool(client)
        client.close unless result
        @pending[idx] = nil
      end
      @pending.compact!
    end

    def move_response_out_queue
      if client = @responses.pop(true)
        @writing << client unless client.write_response
      end
      return client.close unless client.alive?
      @alive_tcps << client
    end

    def put_request_in_pool(client)
      request = client.try_get_request
      return false if request.nil?
      @thread_pool.add do
        response, alive = @app.call(request)
        client.response = response
        client.alive = true if alive
        @responses.push(client)
      end
      true
    end
  end

end