# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/high_water_mark'

RSpec.describe Legion::Extensions::Telemetry::Helpers::HighWaterMark do
  subject(:hwm) { described_class.new }

  describe '#get / #set' do
    it 'stores and retrieves byte offset for a path' do
      hwm.set(path: '/path/session.jsonl', offset: 1234)
      expect(hwm.get(path: '/path/session.jsonl')).to eq(1234)
    end

    it 'returns 0 for unknown paths' do
      expect(hwm.get(path: '/unknown')).to eq(0)
    end
  end

  describe '#ingested?' do
    it 'returns false for unknown paths' do
      expect(hwm.ingested?(path: '/new')).to be false
    end

    it 'returns true after marking complete' do
      hwm.mark_complete(path: '/done')
      expect(hwm.ingested?(path: '/done')).to be true
    end
  end
end
