require 'core/const'


module PlayMe

  class Client


    attr_reader :ip
    def initialize(io, time = 10, log = nil)
      @io = io
      @remote_info = io.peeraddr
      @ip = @remote_info.last
      @to_io = io.to_io
      @log = log
      @requests = []
      @responses = []
      @alive = false
      @timeout = Time.now.to_i + time
      @buffer = nil
    end


    def alive?
      @alive
    end

    def alive=(bool)
      @alive = bool
    end

    def request
      @requests.shift
    end

    def put_response(response)
      @responses << response
    end
    alias << put_response

    def timeout?(current = Time.now.to_i)
      current > @timeout
    end

    def close
      begin
        @io.close
      rescue IOError
        # add log later
      end
    end

    def try_read
      begin
        if @buffer.nil?
          @buffer = @io.read_nonblock(CHUNK_SIZE)
        else
          @buffer << @io.read_nonblock(CHUNK_SIZE)
        end
        if @buffer && @buffer.end_with?("\r\n")
          @requests << @buffer
          @buffer = nil
          return true
        end
        return false
      rescue IO::WaitReadable, EOFError
        return false if @buffer.nil?
        if @buffer.end_with?("\r\n")
          @requests << @buffer
          @buffer = nil
          return true
        end
        return false
      rescue SystemCallError, IOError => error
        throw :error_closed, error
      end
    end


    def try_write
      begin
        response = @responses.shift
        left = @io.write_nonblock(response)
        return true if left == response.bytes.size
        @responses.unshift response.slice!(0, left)
        return false
      rescue IO::WaitWritable
        @responses.unshift(response)
        return false
      rescue SystemCallError, IOError => error
        throw :error_closed, error
      end
    end

  end

end