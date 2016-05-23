require 'spec_helper'

RSpec.describe Sidekiq::Opentsdb::ServerMiddleware do
  let(:worker)    { double('Dummy worker') }
  let(:msg)       { { queue: 'default' } }
  let(:queue)     { nil }
  let(:clean_job) { -> {} }

  let(:opentsdb_client) { double(:put) }

  before(:each) do
    # Mocks sidekiq statistics
    sidekiq_stats = double(retry_size: 10, dead_size: 20)
    allow(Sidekiq::Stats).to receive(:new).and_return(sidekiq_stats)

    # Mocks OpenTSDB calls
    allow(::OpenTSDB::Client).to receive(:new).and_return(opentsdb_client)
  end

  subject { described_class.new(opentsdb_hostname: '', opentsdb_port: '').call(worker, msg, queue, &clean_job) }

  describe '#call' do
    context 'invalid configuration' do
      it 'raises an error if the opentsdb parameters are missing' do
        expect do
          described_class.new(opentsdb_hostname: '')
        end.to raise_error('[sidekiq-opentsdb] OpenTSDB configuration not found...')
      end
    end

    describe 'OpenTSDB call' do
      it 'sends two metrics' do
        expect(opentsdb_client).to receive(:put).twice

        subject
      end

      it 'sets the correct metric name' do
        expect(opentsdb_client).to receive(:put).once.with(
          hash_including(metric: 'nine.sidekiq.queues.retry_queue_size')
        )

        expect(opentsdb_client).to receive(:put).once.with(
          hash_including(metric: 'nine.sidekiq.queues.dead_queue_size')
        )

        subject
      end

      it 'sends the correct value for each metric' do
        expect(opentsdb_client).to receive(:put).once.with(
          hash_including(metric: /retry_queue_size/, value: 10)
        )

        expect(opentsdb_client).to receive(:put).once.with(
          hash_including(metric: /dead_queue_size/, value: 20)
        )

        subject
      end

      it 'sends a timestamp' do
        expect(opentsdb_client).to receive(:put).twice.with(hash_including(timestamp: Fixnum))

        subject
      end

      describe 'tags' do
        context 'Rails app' do
          before(:each) do
            FAKE_RAILS = stub_const('Rails', double)

            fake_rails_app = double(class: double(parent_name: 'MyApp'))
            allow(FAKE_RAILS).to receive(:application).and_return(fake_rails_app)
          end

          it 'sets the application name' do
            expect(opentsdb_client).to receive(:put).twice.with(
              hash_including(tags: { app: 'MyApp' })
            )

            subject
          end
        end

        context 'non-Rails app' do
          it 'sets the application name to unknown' do
            expect(opentsdb_client).to receive(:put).twice.with(
              hash_including(tags: { app: 'unknown' })
            )

            subject
          end
        end
      end
    end
  end
end
