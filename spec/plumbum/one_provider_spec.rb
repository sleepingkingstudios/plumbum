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

  describe '#value' do
    include_examples 'should define reader', :value, nil

    wrap_deferred 'when initialized with value: nil' do
      it { expect(provider.value).to be nil }
    end

    wrap_deferred 'when initialized with a value' do
      it { expect(provider.value).to be value }
    end
  end

  wrap_deferred 'when initialized with value: nil' do
    let(:valid_pairs) { { key => nil } }

    include_deferred 'should implement the Provider interface'
  end

  wrap_deferred 'when initialized with a value' do
    let(:valid_pairs) { { key => value } }

    include_deferred 'should implement the Provider interface'
  end
end
