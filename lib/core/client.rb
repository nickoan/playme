

module PlayMe


  class Client

    class ClientReadingError
    end

    attr_reader :request

    def initialize(io)
      @client_io = io
      @to_io = io.to_io
      @req_data = nil
      @request = nil
      @response = nil
      @time_out_at = Time.now.to_i + 30
      @alive = false
    end

    def ready_to_operate?
      if try_finishing?
        @request = StringIO.new(@data)
        return true
      end
      false
    end

    def ready_to_close?
      return true if try_write?
      false
    end

    def close
      @client_io.close
    end

    def alive?
      return @alive
    end

    def alive=(status = true)
      raise TypeError, 'alive must be a boolean' unless status.is_a?(TrueClass)
      @alive = status
    end

    def body=(str)
      @response = str
    end

    def timed_out?(now = Time.now.to_i)
      return now > @time_out_at
    end


    def to_io
      @to_io
    end



    private

    def try_finishing?
      begin
        data = @client_io.read_nonblock(CHUNK_SIZE)
        set_in_data data
      rescue Errno::EAGAIN
        return false
      rescue SystemCallError, IOError
        raise ClientReadingError, 'Connection error detected during read'
      rescue EOFError
        return true
      end
      false
    end

    def try_write?
      begin
        @client_io.write_nonblock(@response)
        return true
      rescue SystemCallError, IOError
        raise ClientReadingError, 'Connection error detected during write'
      end
    end

    def set_in_data(data)
      if @req_data
        @req_data << data
      else
        @req_data = data
      end
    end

  end
end