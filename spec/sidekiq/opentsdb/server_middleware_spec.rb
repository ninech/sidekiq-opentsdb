require 'spec_helper'

RSpec.describe Sidekiq::Opentsdb::ServerMiddleware do
  let(:worker)    { double('Dummy worker') }
  let(:msg)       { { queue: 'default' } }
  let(:queue)     { nil }
  let(:clean_job) { -> {} }

  let(:sidekiq_stats) do
    {
      processed: 1, failed: 2, scheduled_size: 3, retry_size: 10,
      dead_size: 20, processes_size: 1, default_queue_latency: 50,
      workers_size: 5, enqueued: 1
    }
  end

  let(:opentsdb_client) { double(:put) }

  before(:each) do
    # Mocks sidekiq statistics
    allow(Sidekiq::Stats).to receive(:new).and_return(double(sidekiq_stats))

    # Mocks OpenTSDB calls
    allow(::OpenTSDB::Client).to receive(:new).and_return(opentsdb_client)
  end

  subject { described_class.new(opentsdb_hostname: '', opentsdb_port: '').call(worker, msg, queue, &clean_job) }

  describe '#initialize' do
    it 'raises an error if the opentsdb parameters are missing' do
      expect do
        described_class.new(opentsdb_hostname: '')
      end.to raise_error('[sidekiq-opentsdb] OpenTSDB configuration not found...')

      expect do
        described_class.new(opentsdb_port: '')
      end.to raise_error('[sidekiq-opentsdb] OpenTSDB configuration not found...')
    end
  end

  describe '#call' do
    it 'launches the job passed in' do
      allow(opentsdb_client).to receive(:put)

      expect do |b|
        described_class.new(opentsdb_hostname: '', opentsdb_port: '').call(worker, msg, queue, &b)
      end.to yield_with_no_args
    end

    describe 'error handling' do
      it 'does not stop the job if there has been a problem when connecting to OpenTSDB' do
        expect(opentsdb_client).to receive(:put).and_raise(::OpenTSDB::Errors::UnableToConnectError)

        expect { subject }.to_not raise_error
      end
    end

    describe 'metrics filtering' do
      let(:metrics_subset) { %w(processed failed scheduled_size retry_size) }

      it 'does not filter keys if no filter has been applied' do
        expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times

        subject
      end

      it 'can filter using the only keyword' do
        expect(opentsdb_client).to receive(:put).exactly(metrics_subset.size).times

        described_class.new(opentsdb_hostname: '', opentsdb_port: '', only: metrics_subset).
          call(worker, msg, queue, &clean_job)
      end

      it 'can filter using the except keyword' do
        expect(opentsdb_client).to receive(:put).
          exactly(sidekiq_stats.size - metrics_subset.size).times

        described_class.new(opentsdb_hostname: '', opentsdb_port: '', except: metrics_subset).
          call(worker, msg, queue, &clean_job)
      end
    end

    describe 'OpenTSDB call' do
      it 'connects to the client with correct credentials' do
        expect(::OpenTSDB::Client).to receive(:new).with(hostname: 'host.test', port: '1234')
        expect(opentsdb_client).to receive(:put)

        described_class.new(opentsdb_hostname: 'host.test', opentsdb_port: '1234', only: ['processed']).
          call(worker, msg, queue, &clean_job)
      end

      it 'sends nine metrics' do
        expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times

        subject
      end

      it 'sets the correct metric name' do
        sidekiq_stats.each do |sidekiq_metric, _|
          expect(opentsdb_client).to receive(:put).once.with(
            hash_including(metric: "sidekiq.stats.#{sidekiq_metric}")
          )
        end

        subject
      end

      it 'sends the correct value for each metric' do
        sidekiq_stats.each do |sidekiq_metric, expected_value|
          expect(opentsdb_client).to receive(:put).once.with(
            hash_including(metric: /#{sidekiq_metric}/, value: expected_value)
          )
        end

        subject
      end

      it 'sends a timestamp' do
        expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
          hash_including(timestamp: Fixnum)
        )

        subject
      end

      describe 'metric prefix' do
        subject do
          described_class.new(opentsdb_hostname: '', opentsdb_port: '', metric_prefix: 'nine').
            call(worker, msg, queue, &clean_job)
        end

        it 'defaults to the blank metric prefix if none are provided' do
          expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
            hash_including(metric: /sidekiq\./)
          )

          subject
        end

        it 'sets the correct prefixed metric name' do
          expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
            hash_including(metric: /nine\.sidekiq\./)
          )

          subject
        end
      end

      describe 'tags' do
        describe 'host' do
          before(:each) { allow(Socket).to receive(:gethostname).and_return('MyHost') }

          it 'sets the host' do
            expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
              hash_including(tags: hash_including(host: 'MyHost'))
            )

            subject
          end
        end

        describe 'app' do
          context 'Rails app' do
            before(:each) do
              TOP_RAILS    =    stub_const('Rails', double)
              NESTED_RAILS = stub_const('Sidekiq::Opentsdb::ServerMiddleware::Rails', double)

              fake_rails_app = double(class: double(parent_name: 'MyApp'))
              allow(TOP_RAILS).to receive(:application).and_return(fake_rails_app)
              allow(TOP_RAILS).to receive(:env).and_return('MyEnvironment')

              expect(NESTED_RAILS).to_not receive(:application)
              expect(NESTED_RAILS).to_not receive(:env)
            end

            it 'sets the application name' do
              expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
                hash_including(tags: hash_including(app: 'MyApp'))
              )

              subject
            end

            it 'sets the Rails environment' do
              expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
                hash_including(tags: hash_including(rails_env: 'MyEnvironment'))
              )

              subject
            end
          end

          context 'non-Rails app' do
            it 'does not set the application name' do
              expect(opentsdb_client).to receive(:put).exactly(sidekiq_stats.size).times.with(
                hash_including(tags: hash_excluding(app: 'MyApp'))
              )

              subject
            end
          end
        end
      end
    end
  end
end
