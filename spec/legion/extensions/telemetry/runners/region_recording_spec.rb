# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Telemetry::Runners::Telemetry do
  let(:runner) { described_class }

  before { runner.reset! }

  describe '.record_cross_region' do
    it 'increments the counter for a route pair' do
      runner.record_cross_region(from_region: 'us-east-2', to_region: 'us-west-2')
      result = runner.record_cross_region(from_region: 'us-east-2', to_region: 'us-west-2')
      expect(result[:count]).to eq(2)
    end

    it 'tracks separate route pairs independently' do
      runner.record_cross_region(from_region: 'us-east-2', to_region: 'us-west-2')
      runner.record_cross_region(from_region: 'eu-west-1', to_region: 'us-east-2')
      stats = runner.region_stats
      expect(stats[:cross_region]['us-east-2->us-west-2']).to eq(1)
      expect(stats[:cross_region]['eu-west-1->us-east-2']).to eq(1)
    end

    it 'returns success' do
      result = runner.record_cross_region(from_region: 'a', to_region: 'b')
      expect(result[:success]).to be true
    end

    it 'is thread-safe' do
      threads = Array.new(10) do
        Thread.new do
          50.times { runner.record_cross_region(from_region: 'us-east-2', to_region: 'us-west-2') }
        end
      end
      threads.each(&:join)
      stats = runner.region_stats
      expect(stats[:cross_region]['us-east-2->us-west-2']).to eq(500)
    end
  end

  describe '.record_replication_lag' do
    it 'stores the lag sample for a region' do
      runner.record_replication_lag(region: 'us-west-2', lag_seconds: 1.5)
      stats = runner.region_stats
      expect(stats[:replication_lag]['us-west-2'][:lag_seconds]).to eq(1.5)
    end

    it 'overwrites previous lag value' do
      runner.record_replication_lag(region: 'us-west-2', lag_seconds: 3.0)
      runner.record_replication_lag(region: 'us-west-2', lag_seconds: 0.5)
      stats = runner.region_stats
      expect(stats[:replication_lag]['us-west-2'][:lag_seconds]).to eq(0.5)
    end

    it 'includes a recorded_at timestamp' do
      runner.record_replication_lag(region: 'us-west-2', lag_seconds: 1.0)
      stats = runner.region_stats
      expect(stats[:replication_lag]['us-west-2'][:recorded_at]).to be_an Integer
    end

    it 'returns success' do
      result = runner.record_replication_lag(region: 'us-west-2', lag_seconds: 2.0)
      expect(result[:success]).to be true
    end
  end

  describe '.region_stats' do
    it 'returns success' do
      result = runner.region_stats
      expect(result[:success]).to be true
    end

    it 'returns empty cross_region when nothing recorded' do
      result = runner.region_stats
      expect(result[:cross_region]).to be_empty
    end

    it 'returns empty replication_lag when nothing recorded' do
      result = runner.region_stats
      expect(result[:replication_lag]).to be_empty
    end

    it 'includes a timestamp' do
      result = runner.region_stats
      expect(result[:timestamp]).to be_an Integer
    end
  end
end
