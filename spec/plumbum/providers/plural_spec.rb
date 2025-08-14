# frozen_string_literal: true

require 'plumbum/providers/plural'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Providers::Plural do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(values) }

  let(:described_class) { Spec::Provider }
  let(:values)          { { 'option' => 'value', 'number' => 123 } }
  let(:valid_pairs)     { values }

  example_class 'Spec::Provider' do |klass|
    klass.include Plumbum::Providers::Plural # rubocop:disable RSpec/DescribedClass

    klass.define_method :initialize do |values|
      @values = values
    end
  end

  include_deferred 'should implement the Provider interface'

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
          "#{values.keys.first.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.set(values.keys.first.to_s, value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    describe 'with an valid Symbol', :aggregate_failures do
      let(:error_message) do
        "unable to change immutable value for #{provider.class} with key " \
          "#{values.keys.first.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.set(values.keys.first.to_sym, value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end
  end

  describe '#values' do
    include_examples 'should define reader', :values, -> { values }
  end
end
