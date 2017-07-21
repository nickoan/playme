require 'stringio'


module PlayMe


  class Client

    class ClientReadingError
    end

    attr_reader :request

    def initialize(io)
      @client_io = io
      @to_io = io.to_io
      @buffer = nil
      @requests = Queue.new
      @response = Queue.new
      @time_out_at = Time.now.to_i + 30
      @need_alive = false
    end

    def ready_to_operate?
      try_finishing?
    end

    def ready_to_close?
      try_write?
    end

    def close
      @client_io.close
    end

    def need_alive?
      return @need_alive
    end

    def need_alive=(status = true)
      raise TypeError, 'alive must be a boolean' unless status.is_a?(TrueClass)
      @need_alive = status
    end

    def response=(str)
      @response = str
    end

    def timed_out?(now = Time.now.to_i)
      return now > @time_out_at
    end


    def to_io
      @to_io
    end

    # def ready?
    #   read = IO.select([self])
    #   return true if read and read[0]
    # end

    private

    def try_finishing?
      begin
        read_buffer_from_io
      rescue IO::WaitReadable
        return false
      rescue Errno::EAGAIN
        return false
      rescue SystemCallError, IOError
        raise ClientReadingError, 'Connection error detected during read'
      rescue EOFError
        @requests << StringIO.new(@buffer).string
        @buffer = nil
        return true
      end
      false
    end

    def try_write?
      begin
        byte = @client_io.write_nonblock(@response)
        @response = @response.slice!(0, byte)
        return true if @response.empty?
        return false
      rescue IO::WaitWritable
        return false
      rescue SystemCallError, IOError
        raise ClientReadingError, 'Connection error detected during write'
      end
    end

    def read_buffer_from_io
      data = @client_io.read_nonblock(CHUNK_SIZE)
      if @buffer
        @buffer << data
      else
        @buffer = data
      end
    end

  end
end