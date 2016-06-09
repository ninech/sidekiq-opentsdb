module Sidekiq
  module Opentsdb
    class ServerMiddleware
      SIDEKIQ_METRICS = %w(processed failed scheduled_size retry_size dead_size
                           processes_size default_queue_latency workers_size enqueued).freeze

      def initialize(options = {})
        @options = options

        if !options.key?(:opentsdb_hostname) || !options.key?(:opentsdb_port)
          fail '[sidekiq-opentsdb] OpenTSDB configuration not found...'
        end
      end

      def call(*)
        yield

        sidekiq_stats_metrics_with_values.each do |metric, value|
          opentsdb_client.put metric: "#{metric_prefix}sidekiq.#{metric}", value: value,
                              timestamp: Time.now.to_i, tags: tags
        end
      rescue ::OpenTSDB::Errors::UnableToConnectError
      end

      private

      def sidekiq_stats_metrics_with_values
        sidekiq_stats_instance = Sidekiq::Stats.new
        selected_metrics.inject({}) do |hash, sidekiq_metric|
          hash.merge("stats.#{sidekiq_metric}" => sidekiq_stats_instance.send(sidekiq_metric))
        end
      end

      def selected_metrics
        if @options.key?(:only)
          SIDEKIQ_METRICS.select { |key| @options[:only].include?(key) }
        elsif @options.key?(:except)
          SIDEKIQ_METRICS.select { |key| !@options[:except].include?(key) }
        else
          SIDEKIQ_METRICS
        end
      end

      def tags
        Tags.new(@options).to_hash
      end

      def metric_prefix
        @options.key?(:metric_prefix) ? "#{@options[:metric_prefix]}." : ''
      end

      def opentsdb_client
        @opentsdb_client ||= ::OpenTSDB::Client.new hostname: @options[:opentsdb_hostname],
                                                    port:     @options[:opentsdb_port]
      end
    end
  end
end
