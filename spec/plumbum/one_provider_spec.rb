# frozen_string_literal: true

require 'plumbum/one_provider'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::OneProvider do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(key, **keywords) }

  deferred_context 'when initialized with a value' do
    let(:value)    { 'value' }
    let(:keywords) { super().merge(value:) }
  end

  deferred_context 'when initialized with value: nil' do
    let(:value)    { nil }
    let(:keywords) { super().merge(value:) }
  end

  let(:key)         { 'option' }
  let(:options)     { {} }
  let(:keywords)    { options }
  let(:valid_key)   { key }
  let(:valid_pairs) { {} }

  describe '.new' do
    define_method :call_method do |key|
      described_class.new(key)
    end

    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(1).argument
        .and_keywords(:value)
        .and_any_keywords
    end

    include_deferred 'should validate the key'
  end

  include_deferred 'should implement the Provider interface'

  describe '#get' do
    describe 'with a valid String' do
      it { expect(provider.get(key.to_s)).to be nil }
    end

    describe 'with a valid Symbol' do
      it { expect(provider.get(key.to_sym)).to be nil }
    end
  end

  describe '#has?' do
    describe 'with a valid String' do
      it { expect(provider.has?(key.to_s)).to be false }
    end

    describe 'with a valid Symbol' do
      it { expect(provider.has?(key.to_sym)).to be false }
    end
  end

  describe '#key' do
    include_examples 'should define reader', :key, -> { key }
  end

  describe '#options' do
    it { expect(provider.options).to be == options }

    context 'when initialized with options' do
      let(:options) { super().merge('custom_option' => 'custom value') }

      it { expect(provider.options).to be == options }
    end

    wrap_deferred 'when initialized with a value' do
      it { expect(provider.options).to be == options }
    end
  end

  describe '#set' do
    let(:invalid_key)   { defined?(super()) ? super() : :invalid }
    let(:changed_value) { Object.new.freeze }

    describe 'with an invalid String', :aggregate_failures do
      let(:error_message) do
        "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
      end

      it 'should raise an exception' do
        expect { provider.set(invalid_key.to_s, changed_value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with an invalid Symbol', :aggregate_failures do
      let(:error_message) do
        "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
      end

      it 'should raise an exception' do
        expect { provider.set(invalid_key.to_sym, changed_value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with an valid String', :aggregate_failures do
      let(:error_message) do
        "unable to change immutable value for #{provider.class} with key " \
          "#{valid_key.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.set(valid_key.to_s, changed_value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    describe 'with a valid Symbol', :aggregate_failures do
      let(:error_message) do
        "unable to change immutable value for #{provider.class} with key " \
          "#{valid_key.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.set(valid_key.to_sym, changed_value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    context 'when initialized with read_only: false' do
      let(:options) { super().merge(read_only: false) }

      it { expect(provider.read_only?).to be false }

      describe 'with an valid String', :aggregate_failures do
        it 'should update the value' do
          expect { provider.set(valid_key.to_s, changed_value) }.to(
            change { provider.get(valid_key) }.to(be == changed_value)
          )
        end
      end

      describe 'with an valid Symbol', :aggregate_failures do
        it 'should update the value' do
          expect { provider.set(valid_key.to_sym, changed_value) }.to(
            change { provider.get(valid_key) }.to(be == changed_value)
          )
        end
      end
    end
  end

  describe '#value' do
    include_examples 'should define reader', :value, nil

    wrap_deferred 'when initialized with value: nil' do
      it { expect(provider.value).to be nil }
    end

    wrap_deferred 'when initialized with a value' do
      it { expect(provider.value).to be value }
    end
  end

  describe '#value=' do
    let(:changed_value) { Object.new.freeze }
    let(:error_message) do
      "unable to change immutable value for #{provider.class} with key " \
        "#{provider.key.inspect}"
    end

    include_examples 'should define writer', :value=

    it 'should raise an exception' do
      expect { provider.value = changed_value }
        .to raise_error Plumbum::Errors::ImmutableError, error_message
    end

    context 'when initialized with read_only: false' do
      let(:options) { super().merge(read_only: false) }

      it { expect(provider.value = changed_value).to be == changed_value }

      it 'should update the value' do
        expect { provider.value = changed_value }.to(
          change { provider.get(valid_key) }.to(be == changed_value)
        )
      end

      # rubocop:disable RSpec/RepeatedExampleGroupBody
      wrap_deferred 'when initialized with value: nil' do
        it { expect(provider.value = changed_value).to be == changed_value }

        it 'should update the value' do
          expect { provider.value = changed_value }.to(
            change { provider.get(valid_key) }.to(be == changed_value)
          )
        end
      end

      wrap_deferred 'when initialized with a value' do
        it { expect(provider.value = changed_value).to be == changed_value }

        it 'should update the value' do
          expect { provider.value = changed_value }.to(
            change { provider.get(valid_key) }.to(be == changed_value)
          )
        end
      end
      # rubocop:enable RSpec/RepeatedExampleGroupBody
    end
  end

  wrap_deferred 'when initialized with value: nil' do
    let(:valid_pairs) { { key => nil } }

    include_deferred 'should implement the Provider interface'

    include_deferred 'should implement the singular Provider interface'
  end

  wrap_deferred 'when initialized with a value' do
    let(:valid_pairs) { { key => value } }

    include_deferred 'should implement the Provider interface'

    include_deferred 'should implement the singular Provider interface'
  end
end
