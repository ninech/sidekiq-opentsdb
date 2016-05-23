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
    chain.add Sidekiq::Opentsdb::ServerMiddleware, opentsdb_hostname: 'localhost', opentsdb_port: '4242'
  end
end
```

Change the values to point to your OpenTSDB instance.
