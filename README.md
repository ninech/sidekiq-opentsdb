# Sidekiq::Opentsdb

[![Build Status](https://travis-ci.org/ninech/sidekiq-opentsdb.svg?branch=master)](https://travis-ci.org/ninech/sidekiq-opentsdb)

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

# Tags
app: 'MyApp'                     # (optional) Your app name (Rails app name if available)
environment: 'staging'           # (optional) Your app environment (default: ENV['RACK_ENV'])
```

## About

This gem is currently maintained and funded by [nine](https://nine.ch).

[![logo of the company 'nine'](https://logo.apps.at-nine.ch/Dmqied_eSaoBMQwk3vVgn4UIgDo=/trim/500x0/logo_claim.png)](https://www.nine.ch)
