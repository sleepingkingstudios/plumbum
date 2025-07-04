# frozen_string_literal: true

require 'plumbum/providers/singular'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Providers::Singular do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(key, value) }

  let(:described_class) { Spec::Provider }
  let(:key)             { 'option' }
  let(:value)           { 'value' }
  let(:valid_pairs)     { { key => value } }

  example_class 'Spec::Provider' do |klass|
    klass.include Plumbum::Providers::Singular # rubocop:disable RSpec/DescribedClass

    klass.define_method :initialize do |key, value|
      @key   = key.to_s
      @value = value
    end
  end

  include_deferred 'should implement the Provider interface'

  describe '#key' do
    include_examples 'should define reader', :key, -> { key }
  end

  describe '#value' do
    include_examples 'should define reader', :value, -> { value }
  end
end
