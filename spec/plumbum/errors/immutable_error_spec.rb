# frozen_string_literal: true

require 'plumbum/errors/immutable_error'

RSpec.describe Plumbum::Errors::ImmutableError do
  it { expect(described_class).to be < StandardError }
end
