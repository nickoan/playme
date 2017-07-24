require 'rb_thread_pool'


module PlayMe

  class MeReactor
    def initialize(app, config = {})
      @app = app
      @config = config.dup
      @log = config[:logger]

      @accepts = 100 || @config[:accepts]
      @alives = 1000 || @config[:alives]

      @register = Queue.new
      @responses = Queue.new

      @mutex = Mutex.new
      @pending = []
      @writing = []

      @garbage = []
      @alive_tcps = []

      config[:limit] = 1000 || config[:limit]
      @thread_pool = RBThreadPool::Base.new(config)

      @condition = true

      @reactor_th = nil
    end

    def run!
      @reactor_th = Thread.fork do
        Thread.current.abort_on_exception = true
        Thread.current.name = "PlayMe:Reactor #{Thread.current.to_s}" if Thread.respond_to?(:name=)
        reactor_running_in_thread!
      end
    end

    private

    def reactor_running_in_thread!
      while @condition
        # check pending array, move it to thread pool to process.
        op_pending_to_th_pool

        op_register_to_pending(100)

        op_writing_response

        op_response_to_write(100)

        op_trash_garbage
      end
    end


    def check_timeout(client)
      if client.timeout?
        @garbage << client
        return true
      end
      false
    end


    def op_trash_garbage
      return if @garbage.empty?
      @garbage.each(&:close)
      @garbage = []
    end


    def op_writing_response

      return if @writing.empty?

      size = @writing.size

      size.times do |idx|

        client = @writing[idx]
        client_cpy = nil
        error = nil

        unless check_timeout(client)
          client_cpy, error = catch(:client_error) do
            next unless client.write_response
            if client.alive?
              @alive_tcps << client
            end
            [nil, nil]
          end
        end

        unless error.nil?
          @log.error("client_io_error: #{error.message},backtrace: #{error.backtrace}") unless @log.nil?
          @garbage << client_cpy
        end

        @writing[idx] = nil
      end

      @writing.compact!
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
      client_cpy = nil
      error = nil
      if client = @responses.pop(true)
        client_cpy,error = catch :client_error do
          @writing << client unless client.write_response
        end
      end

      if error.nil?
        return client.close unless client.alive?
        @alive_tcps << client
      else
        @log.error("client_io_error: #{error.message},backtrace: #{error.backtrace}") unless @log.nil?
        @garbage << client_cpy
      end
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