# frozen_string_literal: true

RSpec.describe Legion::Extensions::Telemetry do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be_nil
  end

  it 'defines the Telemetry module' do
    expect(described_class).to be_a(Module)
  end
end
