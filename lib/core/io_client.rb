
module PlayMe
  class IoClient

    def initialize(io)
      @ori_io = io
      @to_io = io.to_io
      @timeout = Time.now.to_i + 30
      @requests = Queue.new
      @responses = Queue.new
      @need_alive = false

      @response_buffer = nil
      @has_response_buffer = false

      @current_buffer = nil
    end

    def try_read?
      begin
        read_from_io
      rescue IO::WaitReadable
        return false
      rescue SystemCallError, IOError => error
        throw :client_error, [self, error]
      rescue EOFError
        @requests << StringIO.new(@current_buffer).string
        @current_buffer = nil
        return true
      end
      false
    end

    def try_get_request
      @requests.pop(true)
    end


    def write_response
      begin
        write_one_response
      rescue IO::WaitWritable
        return false
      rescue SystemCallError, IOError => error
        throw :client_error, [self, error.message]
        #raise ClientWritingError, 'Connection error detected during write'
      end
      true
    end

    def close!
      @ori_io.close
    end
    alias close close!

    def response=(data)
      @responses << data
    end

    def alive=(bool)
      @need_alive = bool
    end

    def alive?
      @need_alive
    end
    alias need_alive? alive?


    def timeout?(time = Time.now.to_i)
      @timeout > time
    end

    private

    def read_from_io
      data = @ori_io.read_nonblock(CHUNK_SIZE)
      if @current_buffer.nil?
        @current_buffer = data
      else
        @current_buffer << data
      end
    end

    def write_one_response
      if @has_response_buffer
        data = @response_buffer
      else
        data = @responses.pop(true)
        return if data.nil?
      end
      left = @ori_io.write_nonblock(data)
      @response_buffer = data.slice!(0, left)
      @has_response_buffer = false if @has_response_buffer and @response_buffer.empty?
    end

  end
end