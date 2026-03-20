# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Telemetry::Runners::Telemetry privacy mode' do
  let(:runner) { Legion::Extensions::Telemetry::Runners::Telemetry }

  before { runner.reset! }

  def store_pending_event
    runner.event_store.store(event: {
                               event_type:  :tool_call,
                               session_id:  'test-session',
                               source:      :test,
                               timestamp:   Time.now,
                               tool_name:   'Read',
                               tool_input:  {},
                               duration_ms: 10,
                               tokens:      {},
                               error:       nil,
                               metadata:    {}
                             })
    runner.event_store.pending.push(runner.event_store.events.last)
  end

  context 'when enterprise privacy is enabled via Legion::Settings' do
    before do
      stub_const('Legion::Settings', Class.new do
        def self.enterprise_privacy?
          true
        end
      end)
      store_pending_event
    end

    it 'does not publish to AMQP' do
      result = runner.publish_pending
      expect(result[:published]).to eq(0)
    end

    it 'returns a suppressed result' do
      result = runner.publish_pending
      expect(result[:suppressed]).to be true
      expect(result[:reason]).to match(/enterprise_data_privacy/)
    end

    it 'clears the pending queue' do
      runner.publish_pending
      expect(runner.event_store.pending).to be_empty
    end
  end

  context 'when enterprise privacy is enabled via ENV' do
    before do
      # Remove any existing Settings stub
      if Legion.const_defined?('Settings')
        # Settings doesn't respond to enterprise_privacy? in this test context
        allow(Legion::Settings).to receive(:respond_to?).with(:enterprise_privacy?).and_return(false)
      end
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with('LEGION_ENTERPRISE_PRIVACY').and_return('true')
      store_pending_event
    end

    it 'suppresses publishing' do
      result = runner.publish_pending
      expect(result[:suppressed]).to be true
    end
  end

  context 'when enterprise privacy is not enabled' do
    before do
      if defined?(Legion::Settings) && Legion::Settings.respond_to?(:enterprise_privacy?)
        allow(Legion::Settings).to receive(:enterprise_privacy?).and_return(false)
      end
      store_pending_event
    end

    it 'does not suppress publishing' do
      result = runner.publish_pending
      expect(result).not_to have_key(:suppressed)
    end
  end
end
