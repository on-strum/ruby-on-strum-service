# frozen_string_literal: true

RSpec.describe OnStrum::Service::Error::Runtime do
  it { expect(described_class).to be_const_defined(:NOT_IMPLEMENTED) }
  it { expect(described_class).to be < ::RuntimeError }
end
