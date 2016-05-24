module Sidekiq
  module Opentsdb
    VERSION = File.read(File.expand_path('../../../../VERSION', __FILE__).strip).chomp
  end
end
