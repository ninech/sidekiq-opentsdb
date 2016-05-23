module Sidekiq
  module Opentsdb
    class ServerMiddleware
      def initialize(options = {})
        if !options.key?(:opentsdb_hostname) || !options.key?(:opentsdb_port)
          fail '[sidekiq-opentsdb] OpenTSDB configuration not found...'
        end

        @opentsdb_hostname = options[:opentsdb_hostname]
        @opentsdb_port     = options[:opentsdb_port]
      end

      def call(*)
        yield

        metrics_with_values = {
          'queues.retry_queue_size' => Sidekiq::Stats.new.retry_size,
          'queues.dead_queue_size'  => Sidekiq::Stats.new.dead_size,
        }

        metrics_with_values.each do |metric, value|
          opentsdb_client.put metric: "nine.sidekiq.#{metric}", value: value,
                              timestamp: Time.now.to_i, tags: { app: application_name }
        end
      end

      private

      def application_name
        return 'unknown' unless defined?(Rails)

        Rails.application.class.parent_name
      end

      def opentsdb_client
        @opentsdb_client ||= ::OpenTSDB::Client.new hostname: @opentsdb_hostname,
                                                    port:     @opentsdb_port
      end
    end
  end
end
