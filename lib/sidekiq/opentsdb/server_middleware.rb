module Sidekiq
  module Opentsdb
    class ServerMiddleware
      def initialize(options = {})
        if !options.key?(:opentsdb_hostname) || !options.key?(:opentsdb_port)
          fail '[sidekiq-opentsdb] OpenTSDB configuration not found...'
        end

        @metric_prefix     = options.key?(:metric_prefix) ? "#{options[:metric_prefix]}." : ''
        @opentsdb_hostname = options[:opentsdb_hostname]
        @opentsdb_port     = options[:opentsdb_port]
      end

      def call(*)
        yield

        metrics_with_values = {
          'queues.retry_size' => Sidekiq::Stats.new.retry_size,
          'queues.dead_size'  => Sidekiq::Stats.new.dead_size,
        }

        metrics_with_values.each do |metric, value|
          opentsdb_client.put metric: "#{@metric_prefix}sidekiq.#{metric}", value: value,
                              timestamp: Time.now.to_i, tags: construct_tags
        end
      end

      private

      def construct_tags
        tags = {}

        tags[:host] = Socket.gethostname
        tags[:app]  = Rails.application.class.parent_name if defined?(Rails)

        tags
      end

      def opentsdb_client
        @opentsdb_client ||= ::OpenTSDB::Client.new hostname: @opentsdb_hostname,
                                                    port:     @opentsdb_port
      end
    end
  end
end
