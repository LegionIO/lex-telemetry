# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Telemetry::Runners::Telemetry, '.region_metrics' do
  let(:runner) { described_class }

  before { runner.reset! }

  context 'when Legion::Region is defined' do
    before do
      stub_const('Legion::Region', Module.new)
      allow(Legion::Region).to receive(:current).and_return('us-east-2')
      allow(Legion::Region).to receive(:primary).and_return('us-east-2')
      allow(Legion::Region).to receive(:failover).and_return('us-west-2')
      allow(Legion::Region).to receive(:peers).and_return(%w[us-east-2 us-west-2])
    end

    it 'returns success' do
      result = runner.region_metrics
      expect(result[:success]).to be true
    end

    it 'includes current region' do
      result = runner.region_metrics
      expect(result[:region][:current]).to eq('us-east-2')
    end

    it 'includes primary region' do
      result = runner.region_metrics
      expect(result[:region][:primary]).to eq('us-east-2')
    end

    it 'includes failover region' do
      result = runner.region_metrics
      expect(result[:region][:failover]).to eq('us-west-2')
    end

    it 'includes peers' do
      result = runner.region_metrics
      expect(result[:region][:peers]).to eq(%w[us-east-2 us-west-2])
    end

    it 'sets is_primary when current matches primary' do
      result = runner.region_metrics
      expect(result[:is_primary]).to be true
    end

    it 'sets is_primary false when current differs from primary' do
      allow(Legion::Region).to receive(:current).and_return('us-west-2')
      result = runner.region_metrics
      expect(result[:is_primary]).to be false
    end

    it 'includes a timestamp' do
      result = runner.region_metrics
      expect(result[:timestamp]).to be_an Integer
    end
  end

  context 'when Legion::Region is not defined' do
    before do
      hide_const('Legion::Region') if defined?(Legion::Region)
    end

    it 'returns success with nil region values' do
      result = runner.region_metrics
      expect(result[:success]).to be true
      expect(result[:region][:current]).to be_nil
    end

    it 'returns empty peers array' do
      result = runner.region_metrics
      expect(result[:region][:peers]).to eq([])
    end

    it 'sets is_primary to falsey' do
      result = runner.region_metrics
      expect(result[:is_primary]).to be_falsey
    end
  end
end
