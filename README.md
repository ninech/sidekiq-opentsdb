# Sidekiq::Opentsdb

Sidekiq middleware that sends useful Sidekiq statistics to OpenTSDB.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sidekiq-opentsdb'
```

And then execute:

    $ bundle

## Usage

You need to add the middleware to your call stack. To do so, put the folllowing code in an initializer (ideally `sidekiq.rb`):

```ruby
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Opentsdb::ServerMiddleware, opentsdb_hostname: 'localhost', opentsdb_port: '4242',
                                                   metric_prefix: 'nine', only: %w(retry_size dead_size)
  end
end
```

### Options

opentsdb_hostname: (required) Hostname of your opentsdb server.
opentsdb_port:     (required) Port of your opentsdb server.

metric_prefix: (optional) Prefix of the metric keys (default: '').
only: [Array] (optional) Only send the given metrics to OpenTSDB.
except: [Array] (optional) Send all but the given metrics to OpenTSDB.
