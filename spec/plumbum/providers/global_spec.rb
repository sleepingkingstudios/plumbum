# frozen_string_literal: true

require 'plumbum/providers/global'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Providers::Global do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(key:, **options) }

  let(:key)         { 'option' }
  let(:options)     { {} }
  let(:valid_pairs) { {} }

  it { expect(provider).to be_a Module }

  include_deferred 'should implement the Provider interface'

  describe '.new' do
    define_method :call_method do |key|
      described_class.new(key:)
    end

    it 'should define the constructor' do
      expect(provider)
        .to respond_to(:initialize, true)
        .with(0).arguments
        .and_keywords(:key, :mutable, :value)
    end

    include_deferred 'should validate the key'
  end

  describe '#get' do
    describe 'with a matching key as a String' do
      it { expect(provider.get(key.to_s)).to be nil }
    end

    describe 'with a matching key as a Symbol' do
      it { expect(provider.get(key.to_sym)).to be nil }
    end

    context 'when initialized with a value' do
      let(:value)   { 'constructor value' }
      let(:options) { super().merge(value:) }

      describe 'with a matching key as a String' do
        it { expect(provider.get(key.to_s)).to be value }
      end

      describe 'with a matching key as a Symbol' do
        it { expect(provider.get(key.to_sym)).to be value }
      end
    end

    context 'when the value is set' do
      let(:new_value) { 'writer value' }

      before(:example) { provider.value = new_value }

      describe 'with a matching key as a String' do
        it { expect(provider.get(key.to_s)).to be new_value }
      end

      describe 'with a matching key as a Symbol' do
        it { expect(provider.get(key.to_sym)).to be new_value }
      end
    end
  end

  describe '#has?' do
    describe 'with a matching key as a String' do
      it { expect(provider.has?(key.to_s)).to be false }
    end

    describe 'with a matching key as a Symbol' do
      it { expect(provider.has?(key.to_sym)).to be false }
    end

    context 'when initialized with a value' do
      let(:value)   { 'constructor value' }
      let(:options) { super().merge(value:) }

      describe 'with a matching key as a String' do
        it { expect(provider.has?(key.to_s)).to be true }
      end

      describe 'with a matching key as a Symbol' do
        it { expect(provider.has?(key.to_sym)).to be true }
      end
    end

    context 'when the value is set' do
      let(:new_value) { 'writer value' }

      before(:example) { provider.value = new_value }

      describe 'with a matching key as a String' do
        it { expect(provider.has?(key.to_s)).to be true }
      end

      describe 'with a matching key as a Symbol' do
        it { expect(provider.has?(key.to_sym)).to be true }
      end
    end
  end

  describe '#key' do
    include_examples 'should define reader', :key, -> { key }
  end

  describe '#mutable?' do
    include_examples 'should define predicate', :mutable?, false

    context 'when initialized with mutable: false' do
      let(:options) { super().merge(mutable: false) }

      it { expect(provider.mutable?).to be false }
    end

    context 'when initialized with mutable: true' do
      let(:options) { super().merge(mutable: true) }

      it { expect(provider.mutable?).to be true }
    end
  end

  describe '#value' do
    include_examples 'should define reader', :value, nil

    context 'when initialized with value: nil' do
      let(:value)   { nil }
      let(:options) { super().merge(value:) }

      it { expect(provider.value).to be value }
    end

    context 'when initialized with value: a value' do
      let(:value)   { 'constructor value' }
      let(:options) { super().merge(value:) }

      it { expect(provider.value).to be value }
    end

    context 'when the value is set' do
      let(:new_value) { 'writer value' }

      before(:example) { provider.value = new_value }

      it { expect(provider.value).to be new_value }
    end
  end

  describe '#value=' do
    let(:new_value) { 'writer value' }

    include_examples 'should define writer', :value=

    it 'should set the value' do
      expect { provider.value = new_value }
        .to change(provider, :value)
        .to be new_value
    end

    context 'when initialized with value: nil' do
      let(:value)   { nil }
      let(:options) { super().merge(value:) }
      let(:error_message) do
        "unable to change immutable value for #{described_class.name} with " \
          "key #{key.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.value = new_value }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end

      context 'when initialized with mutable: true' do
        let(:options) { super().merge(mutable: true) }

        it 'should set the value' do
          expect { provider.value = new_value }
            .to change(provider, :value)
            .to be new_value
        end
      end
    end

    context 'when initialized with value: a value' do
      let(:value)   { 'constructor value' }
      let(:options) { super().merge(value:) }
      let(:error_message) do
        "unable to change immutable value for #{described_class.name} with " \
          "key #{key.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.value = new_value }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end

      context 'when initialized with mutable: true' do
        let(:options) { super().merge(mutable: true) }

        it 'should set the value' do
          expect { provider.value = new_value }
            .to change(provider, :value)
            .to be new_value
        end
      end
    end

    context 'when the value is set' do
      let(:old_value) { 'previous value' }
      let(:error_message) do
        "unable to change immutable value for #{described_class.name} with " \
          "key #{key.inspect}"
      end

      before(:example) { provider.value = old_value }

      it 'should raise an exception' do
        expect { provider.value = new_value }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end

      context 'when initialized with mutable: true' do
        let(:options) { super().merge(mutable: true) }

        it 'should set the value' do
          expect { provider.value = new_value }
            .to change(provider, :value)
            .to be new_value
        end
      end
    end
  end
end
