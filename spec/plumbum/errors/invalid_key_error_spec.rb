# frozen_string_literal: true

require 'plumbum/errors/invalid_key_error'

RSpec.describe Plumbum::Errors::InvalidKeyError do
  it { expect(described_class).to be < StandardError }
end
