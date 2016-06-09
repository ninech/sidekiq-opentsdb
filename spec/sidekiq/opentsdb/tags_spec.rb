require 'spec_helper'

RSpec.describe Sidekiq::Opentsdb::Tags do
  let(:options) { {} }
  subject { described_class.new(options) }

  describe '#to_hash' do
    it 'includes the current host name' do
      expect(subject.to_hash).to include(host: Socket.gethostname)
    end

    context 'in a Rails app' do
      before do
        rails = stub_const('Rails', double)
        fake_rails_app = double(class: double(parent_name: 'MyApp'))
        allow(rails).to receive(:application).and_return(fake_rails_app)
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return('fake-environment')
      end

      it 'includes the rails app name' do
        expect(subject.to_hash).to include(app: 'MyApp')
      end

      context 'when the app name is defined via the options' do
        let(:options) { { app: 'Facebook2' } }

        it 'includes the app name from the options' do
          expect(subject.to_hash).to include(app: 'Facebook2')
        end
      end

      it 'includes the rails environment' do
        expect(subject.to_hash).to include(environment: 'fake-environment')
      end

      context 'when the environment is defined via the options' do
        let(:options) { { environment: 'test' } }

        it 'includes the environment from the options' do
          expect(subject.to_hash).to include(environment: 'test')
        end
      end
    end

    context 'without a Rails context' do
      it 'does not include the app tag by default' do
        expect(subject.to_hash).to_not include(:app)
      end

      context 'when the app is defined in the options' do
        let(:options) { { app: 'myapp' } }

        it 'includes the app tag' do
          expect(subject.to_hash).to include(app: 'myapp')
        end
      end
    end
  end
end
