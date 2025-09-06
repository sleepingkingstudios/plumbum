# frozen_string_literal: true

require 'plumbum/providers/lazy'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Providers::Lazy do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { Spec::Provider.new(**options) }

  let(:options)     { {} }
  let(:valid_pairs) { {} }

  example_class 'Spec::Provider' do |klass|
    klass.include Plumbum::Provider
    klass.include Plumbum::Providers::Lazy # rubocop:disable RSpec/DescribedClass

    klass.define_method :initialize do |value: Plumbum::UNDEFINED, **options|
      @options = options
      @value   = value
    end

    klass.define_method :get_value do |key|
      next unless key == 'option'

      @value == Plumbum::UNDEFINED ? nil : @value # rubocop:disable RSpec/InstanceVariable
    end

    klass.define_method :has_value? do |key, allow_undefined: false|
      key == 'option' && (allow_undefined || @value != Plumbum::UNDEFINED) # rubocop:disable RSpec/InstanceVariable
    end
  end

  include_deferred 'should implement the Provider interface'

  describe '#get' do
    describe 'with a valid String' do
      it { expect(provider.get('option')).to be nil }
    end

    describe 'with a valid Symbol' do
      it { expect(provider.get(:option)).to be nil }
    end

    context 'when initialized with value: UNDEFINED' do
      let(:value)   { Plumbum::UNDEFINED }
      let(:options) { super().merge(value:) }

      describe 'with a valid String' do
        it { expect(provider.get('option')).to be nil }
      end

      describe 'with a valid Symbol' do
        it { expect(provider.get(:option)).to be nil }
      end
    end

    context 'when initialized with value: an Object' do
      let(:value)   { 'value' }
      let(:options) { super().merge(value:) }

      describe 'with a valid String' do
        it { expect(provider.get('option')).to be value }
      end

      describe 'with a valid Symbol' do
        it { expect(provider.get(:option)).to be value }
      end
    end

    context 'when initialized with value: a Proc' do
      let(:value)   { -> { 'value' } }
      let(:options) { super().merge(value:) }

      describe 'with a valid String' do
        it { expect(provider.get('option')).to be == value.call }
      end

      describe 'with a valid Symbol' do
        it { expect(provider.get(:option)).to be == value.call }
      end
    end
  end
end
