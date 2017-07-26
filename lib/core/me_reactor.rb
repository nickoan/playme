require 'rb_thread_pool'

require 'rack/response'
module PlayMe

  class MeReactor

    attr_reader :reactor_th
    def initialize(app,config = {})
      @app = app
      @config = config.dup
      @log = config[:logger]
      #@env = env

      @accepts = 100 || @config[:accepts]
      @alives = 1000 || @config[:alives]

      @register = Queue.new
      @responses = Queue.new

      @mutex = Mutex.new
      #@pending = []
      #@writing = []

      @garbage = []
      @alive_tcps = []

      config[:limit] = 1000 || config[:limit]
      @thread_pool = RBThreadPool::Base.new(config)

      @condition = true

      @reactor_th = nil

      @parser = Parser.new
    end

    def run!
      @reactor_th = Thread.fork do
        Thread.current.abort_on_exception = true
        Thread.current.name = "PlayMe:Reactor #{Thread.current.to_s}" if Thread.respond_to?(:name=)
        #Thread.current.priority =
        reactor_running_in_thread!
      end
      @thread_pool.start!
    end

    def regist(io)
      @register << io
    end

    private

    def reactor_running_in_thread!
      puts "reactor start #{Thread.current.inspect}"
      while @condition
        #puts 'while start'
        # check pending array, move it to thread pool to process.
        op_pending_to_th_pool

        op_register_to_pending(100)

        #op_writing_response

        #op_response_to_write(100)

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
      @garbage.each do |value|
        begin
          value.close!
        rescue IOError
          next
        end
      end
      @garbage = []
    end

    #
    # def op_writing_response
    #
    #   return if @writing.empty?
    #
    #   size = @writing.size
    #
    #   size.times do |idx|
    #
    #     client = @writing[idx]
    #     client_cpy = nil
    #     error = nil
    #
    #     unless check_timeout(client)
    #       client_cpy, error = catch(:client_error) do
    #         next unless client.write_response
    #         if client.alive?
    #           @alive_tcps << client
    #         end
    #         [nil, nil]
    #       end
    #     end
    #
    #     check_error_occur?(error, client_cpy)
    #
    #     @writing[idx] = nil
    #   end
    #
    #   @writing.compact!
    # end



    # def op_response_to_write(num)
    #   num.times do
    #     break if @responses.empty?
    #     move_response_out_queue
    #   end
    # end

    def op_register_to_pending(num)
      num.times do |idx|
        break if @register.empty?
        plain_io = @register.pop(true)
        client = ::PlayMe::IoClient.new(plain_io)
        @pending << client
      end
    end


    def op_pending_to_th_pool
      return if @pending.empty?
      @pending.size.times do |idx|
        client = @pending[idx]
        break if client.nil?
        client_cpy, error = catch :client_error do
          next unless client.try_read?
          result = put_request_in_pool(client)
          @pending[idx] = nil
          client.close unless result
          [nil, nil]
        end
        next if check_error_occur?(error, client_cpy)
      end
      @pending.compact!
    end



    # def move_response_out_queue
    #   # client_cpy = nil
    #   # error = nil
    #   # if client = @responses.pop(true)
    #   #   client_cpy, error = catch :client_error do
    #   #     @writing << client unless client.write_response
    #   #     [nil, nil]
    #   #   end
    #   # end
    #   client = @responses.pop(true)
    #
    #   return client.close unless client.alive?
    #   @alive_tcps << client
    #
    # end



    def check_error_occur?(error, client)
      return false if error.nil?
      @log.error("client_io_error: #{error.message},backtrace: #{error.backtrace}") unless @log.nil?
      @garbage << client
      true
    end

    def put_request_in_pool(client)
      request = client.try_get_request
      return false if request.nil?
      @thread_pool.add do
        env = @parser.execute(request)
        response, alive = @app.call(env)
        client.write_response(response)
        if alive
          client.alive = true
        else
          begin

          end
          client.close
        end

      end
      true
    end
  end

end