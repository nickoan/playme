module PlayMe
  class BackendThreads
    def initialize
      @in_queue = Queue.new
      @out_queue = Queue.new
      @pool = []
      @size = 3
      @loop_condition = true
    end

    def start
      @size.times do
        @pool << spawn_thread
      end
    end

    def << (obj)
      @in_queue.push(obj)
    end
    alias push <<

    def >>
      return nil if @out_queue.empty?
      @out_queue.pop(true)
    end
    alias pop >>

    private

    def spawn_thread
      Thread.new { logic_run_in_thread }
    end


    def logic_run_in_thread
      Thread.abort_on_exception = true
      while @loop_condition
        app_block = @in_queue.pop(false)
        @out_queue << app_block.call
        Thread.pass
      end
    end

  end
end