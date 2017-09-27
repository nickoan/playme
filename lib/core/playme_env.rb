module PlayMe
  class PlayMeEnv

    def initialize(env, client)
      @env = env
      @client = client
      @response = nil
    end

    def [](name)
      @env[name]
    end

    def keep_alive!
      @client.alive= true
    end

    def response=(value)
      @client << value
    end

    def done!
      @client
    end
  end
end