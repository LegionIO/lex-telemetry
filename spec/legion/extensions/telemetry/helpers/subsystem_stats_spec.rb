# frozen_string_literal: true

require 'spec_helper'
require 'legion/extensions/telemetry/helpers/subsystem_stats'

RSpec.describe Legion::Extensions::Telemetry::Helpers::SubsystemStats do
  let(:collector) { described_class }

  describe '.collect_transport' do
    context 'when Legion::Transport is not defined' do
      it 'returns nil' do
        hide_const('Legion::Transport')
        expect(collector.collect_transport).to be_nil
      end
    end

    context 'when Legion::Transport is defined' do
      it 'returns a hash or nil' do
        result = collector.collect_transport
        expect(result).to(satisfy { |r| r.nil? || r.is_a?(Hash) })
      end
    end
  end

  describe '.collect_cache' do
    context 'when Legion::Cache is not defined' do
      it 'returns nil' do
        hide_const('Legion::Cache')
        expect(collector.collect_cache).to be_nil
      end
    end

    context 'when Legion::Cache is defined' do
      it 'returns a hash or nil' do
        result = collector.collect_cache
        expect(result).to(satisfy { |r| r.nil? || r.is_a?(Hash) })
      end
    end
  end

  describe '.collect_data' do
    context 'when Legion::Data is not defined' do
      it 'returns nil' do
        hide_const('Legion::Data')
        expect(collector.collect_data).to be_nil
      end
    end

    context 'when Legion::Data is defined' do
      it 'returns a hash or nil' do
        result = collector.collect_data
        expect(result).to(satisfy { |r| r.nil? || r.is_a?(Hash) })
      end
    end
  end

  describe '.collect_llm' do
    context 'when Legion::LLM is not defined' do
      it 'returns nil' do
        expect(collector.collect_llm).to be_nil
      end
    end
  end

  describe '.collect_extensions' do
    context 'when Legion::Extensions is defined' do
      it 'returns a hash or nil' do
        result = collector.collect_extensions
        expect(result).to(satisfy { |r| r.nil? || r.is_a?(Hash) })
      end
    end
  end

  describe '.collect_gaia' do
    context 'when Legion::Gaia is not defined' do
      it 'returns nil' do
        expect(collector.collect_gaia).to be_nil
      end
    end
  end
end
