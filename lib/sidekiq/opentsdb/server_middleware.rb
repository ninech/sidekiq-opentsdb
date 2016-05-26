module Sidekiq
  module Opentsdb
    class ServerMiddleware
      def initialize(options = {})
        if !options.key?(:opentsdb_hostname) || !options.key?(:opentsdb_port)
          fail '[sidekiq-opentsdb] OpenTSDB configuration not found...'
        end

        @sidekiq_metrics = %w(processed failed scheduled_size retry_size dead_size
                              processes_size default_queue_latency workers_size enqueued)

        filter_metrics!(options)

        @metric_prefix     = options.key?(:metric_prefix) ? "#{options[:metric_prefix]}." : ''
        @opentsdb_hostname = options[:opentsdb_hostname]
        @opentsdb_port     = options[:opentsdb_port]
      end

      def call(*)
        yield

        sidekiq_stats_metrics_with_values.each do |metric, value|
          opentsdb_client.put metric: "#{@metric_prefix}sidekiq.#{metric}", value: value,
                              timestamp: Time.now.to_i, tags: construct_tags
        end
      end

      private

      def filter_metrics!(options)
        if options.key?(:only)
          @sidekiq_metrics.select! { |key| options[:only].include?(key) }
        elsif options.key?(:except)
          @sidekiq_metrics.select! { |key| !options[:except].include?(key) }
        end
      end

      def sidekiq_stats_metrics_with_values
        sidekiq_stats_instance = Sidekiq::Stats.new

        @sidekiq_metrics.inject({}) do |hash, sidekiq_metric|
          hash.merge("stats.#{sidekiq_metric}" => sidekiq_stats_instance.send(sidekiq_metric))
        end
      end

      def construct_tags
        tags = {}

        tags[:host] = Socket.gethostname

        if defined?(Rails)
          tags[:app]       = ::Rails.application.class.parent_name
          tags[:rails_env] = ::Rails.env
        end

        tags
      end

      def opentsdb_client
        @opentsdb_client ||= ::OpenTSDB::Client.new hostname: @opentsdb_hostname,
                                                    port:     @opentsdb_port
      end
    end
  end
end
