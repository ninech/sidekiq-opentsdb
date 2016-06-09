module Sidekiq
  module Opentsdb
    class Tags
      def initialize(options = {})
        @options = options
      end

      def to_hash
        {
          host: Socket.gethostname,
          environment: environment,
          app: app,
        }.delete_if { |k, v| v.nil? }
      end

      private

      def environment
        @options[:environment] || ENV['RACK_ENV']
      end

      def app
        @options[:app] || rails_app_name
      end

      def rails_app_name
        ::Rails.application.class.parent_name if defined?(::Rails)
      end
    end
  end
end
