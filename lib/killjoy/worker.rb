module Killjoy
  module Worker
    def initialize
      @mutex = ServerEngine::BlockingFlag.new
      @message_bus = Killjoy::MessageBus.new(config)
    end

    def run
      after_fork

      writers = Spank::IOC.resolve_all(:writer)

      config[:queue_shards].times do |shard|
        @message_bus.run(Killjoy::Consumer.new(writers, shard))
      end
      until @mutex.wait_for_set(config[:heartbeat])
        logger.debug("Heartbeat: [#{Thread.object_id}]")
      end
    end

    def stop
      @message_bus.stop
      @mutex.set!
    end

    private

    def after_fork
      Killjoy::AfterFork.new.call
    end
  end
end
