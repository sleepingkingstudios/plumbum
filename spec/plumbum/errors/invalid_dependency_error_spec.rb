# frozen_string_literal: true

require 'plumbum/errors/invalid_dependency_error'

RSpec.describe Plumbum::Errors::InvalidDependencyError do
  it { expect(described_class).to be < StandardError }
end
