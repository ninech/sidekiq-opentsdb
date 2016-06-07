require 'sidekiq/api'
require 'opentsdb'
require 'socket'

module Sidekiq
  module Opentsdb
  end
end

require 'sidekiq/opentsdb/tags'
require 'sidekiq/opentsdb/server_middleware'
require 'sidekiq/opentsdb/version'
