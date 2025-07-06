# frozen_string_literal: true

require 'plumbum/errors/missing_dependency_error'

RSpec.describe Plumbum::Errors::MissingDependencyError do
  it { expect(described_class).to be < StandardError }
end
