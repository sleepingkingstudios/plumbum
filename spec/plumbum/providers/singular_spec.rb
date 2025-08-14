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

  describe '#set' do
    let(:invalid_key) { :invalid }
    let(:value)       { Object.new.freeze }

    describe 'with an invalid String', :aggregate_failures do
      let(:error_message) do
        "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
      end

      it 'should raise an exception' do
        expect { provider.set(invalid_key.to_s, value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with an invalid Symbol', :aggregate_failures do
      let(:error_message) do
        "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
      end

      it 'should raise an exception' do
        expect { provider.set(invalid_key.to_sym, value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with an valid String', :aggregate_failures do
      let(:error_message) do
        "unable to change immutable value for #{provider.class} with key " \
          "#{key.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.set('option', value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    describe 'with a valid Symbol', :aggregate_failures do
      let(:error_message) do
        "unable to change immutable value for #{provider.class} with key " \
          "#{key.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.set(:option, value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end
  end

  describe '#value' do
    include_examples 'should define reader', :value, -> { value }
  end
end
