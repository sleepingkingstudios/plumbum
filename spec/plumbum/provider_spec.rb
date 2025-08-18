# frozen_string_literal: true

require 'plumbum/provider'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Provider do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { Object.new.extend(described_class) }

  let(:valid_pairs) { {} }

  include_deferred 'should implement the Provider interface', has_options: false

  describe '#options' do
    it { expect(provider.options).to be == {} }
  end

  context 'with a concrete Provider implementation' do
    subject(:provider) { Spec::Provider.new(**options) }

    let(:options)     { {} }
    let(:valid_pairs) { { 'option' => 'value' } }

    example_class 'Spec::Provider' do |klass|
      klass.include Plumbum::Provider # rubocop:disable RSpec/DescribedClass

      klass.define_method :initialize do |**options|
        @options = options
        @value   = 'value'
      end

      klass.define_method :get_value do |key|
        key == 'option' ? @value : nil # rubocop:disable RSpec/InstanceVariable
      end

      klass.define_method :has_value? do |key|
        key == 'option'
      end

      klass.define_method :valid_key? do |key|
        key == 'option'
      end
    end

    include_deferred 'should implement the Provider interface'

    describe '#options' do
      it { expect(provider.options).to be == {} }

      context 'when initialized with options: value' do
        let(:options) { super().merge(key: 'value') }

        it { expect(provider.options).to be == options }
      end
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
            '"option"'
        end

        it 'should raise an exception' do
          expect { provider.set('option', value) }
            .to raise_error Plumbum::Errors::ImmutableError, error_message
        end
      end

      describe 'with a valid Symbol', :aggregate_failures do
        let(:error_message) do
          "unable to change immutable value for #{provider.class} with key " \
            '"option"'
        end

        it 'should raise an exception' do
          expect { provider.set(:option, value) }
            .to raise_error Plumbum::Errors::ImmutableError, error_message
        end
      end

      context 'when the provider is mutable' do
        let(:value) { 'changed_value' }

        before(:example) do
          Spec::Provider.class_eval do
            private

            def mutable?(key) = key == 'option'

            def set_value(_key, value) = @value = value
          end
        end

        describe 'with an valid String', :aggregate_failures do
          it { expect(provider.set('option', value)).to be == value }

          it 'should update the value' do
            expect { provider.set('option', value) }.to(
              change { provider.get('option') }.to(be == value)
            )
          end
        end

        describe 'with an valid Symbol', :aggregate_failures do
          it { expect(provider.set('option', value)).to be == value }

          it 'should update the value' do
            expect { provider.set(:option, value) }.to(
              change { provider.get('option') }.to(be == value)
            )
          end
        end
      end
    end
  end
end
