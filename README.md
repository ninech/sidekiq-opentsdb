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
    middleware_options = {
        opentsdb_hostname: 'localhost',
        opentsdb_port: '4242',
        metric_prefix: 'nine',
        only: %w(retry_size dead_size)
    }
  
    chain.add Sidekiq::Opentsdb::ServerMiddleware, middleware_options
  end
end
```

### Available Options

```ruby
opentsdb_hostname: 'localhost'   # (required) Hostname of your opentsdb server.
opentsdb_port: '4242'            # (required) Port of your opentsdb server.

metric_prefix: 'nine'            # (optional) Prefix of the metric keys (default: '').
only:   %w(retry_size dead_size) # (optional) Only send the given metrics to OpenTSDB.
except: %w(retry_size dead_size) # (optional) Send all but the given metrics to OpenTSDB.
```
