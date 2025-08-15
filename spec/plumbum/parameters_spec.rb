# frozen_string_literal: true

require 'plumbum/parameters'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Parameters do
  subject(:instance) do
    described_class.new(
      *arguments,
      **keywords,
      **dependencies,
      &block
    )
  end

  deferred_context 'when the class includes providers' do
    example_class 'Spec::ManyProvider', Module do |klass|
      klass.include Plumbum::Providers::Plural

      klass.define_method :initialize do |values:|
        tools = SleepingKingStudios::Tools::Toolbelt.instance

        @values = tools.hash_tools.convert_keys_to_strings(values)
      end
    end

    example_constant 'Spec::ConfigProvider' do
      Spec::ManyProvider.new(
        values: { env: 'test', repository: { books: [] }, tools: {} }
      )
    end

    before(:example) { described_class.provider Spec::ConfigProvider }
  end

  deferred_context 'when the class defines dependencies' do
    before(:example) do
      described_class.dependency('env')
      described_class.dependency('tools')
    end
  end

  deferred_context 'when the constructor takes parameters' do
    before(:example) do
      Spec::ParametersConsumer.class_eval do
        def initialize(*arguments, **keywords, &block)
          @arguments = arguments
          @keywords  = keywords
          @block     = block
        end

        attr_reader \
          :arguments,
          :keywords,
          :block
      end
    end
  end

  let(:described_class) { Spec::ParametersConsumer }
  let(:arguments)       { [] }
  let(:keywords)        { {} }
  let(:block)           { nil }
  let(:dependencies)    { {} }

  example_class 'Spec::ParametersConsumer' do |klass|
    klass.include Plumbum::Consumer
    klass.prepend Plumbum::Parameters # rubocop:disable RSpec/DescribedClass
  end

  describe '::Provider' do
    include Plumbum::RSpec::Deferred::ProviderExamples

    subject(:provider) { described_class.new(values:) }

    deferred_context 'when initialized with values: a Hash with String keys' do
      let(:values) do
        {
          'env'        => 'test',
          'repository' => {
            'books' => []
          }
        }
      end
    end

    deferred_context 'when initialized with values: a Hash with Symbol keys' do
      let(:values) do
        {
          env:        'test',
          repository: {
            'books' => []
          }
        }
      end
    end

    let(:described_class) { Plumbum::Parameters::Provider }
    let(:values)          { {} }
    let(:valid_pairs)     { {} }

    describe '.new' do
      it 'should define the constructor' do
        expect(described_class)
          .to be_constructible
          .with(0).arguments
          .and_keywords(:values)
      end

      describe 'with no parameters' do
        it { expect { described_class.new }.not_to raise_error }
      end

      describe 'with values: nil' do
        let(:error_message) { 'values is not an instance of Hash' }

        it 'should raise an exception' do
          expect { described_class.new(values: nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with values: an Object' do
        let(:error_message) { 'values is not an instance of Hash' }

        it 'should raise an exception' do
          expect { described_class.new(values: Object.new.freeze) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    include_deferred 'should implement the Provider interface'

    describe '#get' do
      wrap_deferred 'when initialized with values: a Hash with String keys' do
        let(:valid_pairs) do
          {
            'env'        => values['env'],
            'repository' => values['repository']
          }
        end

        describe 'with an invalid String' do
          it { expect(provider.get('invalid')).to be nil }
        end

        describe 'with an invalid Symbol' do
          it { expect(provider.get(:invalid)).to be nil }
        end

        describe 'with a valid String', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each do |key, value|
              expect(provider.get(key.to_s)).to be value
            end
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each do |key, value|
              expect(provider.get(key.to_sym)).to be value
            end
          end
        end
      end

      wrap_deferred 'when initialized with values: a Hash with Symbol keys' do
        let(:valid_pairs) do
          {
            'env'        => values[:env],
            'repository' => values[:repository]
          }
        end

        describe 'with an invalid String' do
          it { expect(provider.get('invalid')).to be nil }
        end

        describe 'with an invalid Symbol' do
          it { expect(provider.get(:invalid)).to be nil }
        end

        describe 'with a valid String', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each do |key, value|
              expect(provider.get(key.to_s)).to be value
            end
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each do |key, value|
              expect(provider.get(key.to_sym)).to be value
            end
          end
        end
      end
    end

    describe '#has?' do
      wrap_deferred 'when initialized with values: a Hash with String keys' do
        let(:valid_pairs) do
          {
            'env'        => values['env'],
            'repository' => values['repository']
          }
        end

        describe 'with an invalid String' do
          it { expect(provider.has?('invalid')).to be false }
        end

        describe 'with an invalid Symbol' do
          it { expect(provider.has?(:invalid)).to be false }
        end

        describe 'with a valid String', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each_key do |key|
              expect(provider.has?(key.to_s)).to be true
            end
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each_key do |key|
              expect(provider.has?(key.to_sym)).to be true
            end
          end
        end
      end

      wrap_deferred 'when initialized with values: a Hash with Symbol keys' do
        let(:valid_pairs) do
          {
            'env'        => values[:env],
            'repository' => values[:repository]
          }
        end

        describe 'with an invalid String' do
          it { expect(provider.has?('invalid')).to be false }
        end

        describe 'with an invalid Symbol' do
          it { expect(provider.has?(:invalid)).to be false }
        end

        describe 'with a valid String', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each_key do |key|
              expect(provider.has?(key.to_s)).to be true
            end
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each_key do |key|
              expect(provider.has?(key.to_sym)).to be true
            end
          end
        end
      end
    end

    describe '#values' do
      it 'should define the reader' do
        expect(provider).to define_reader(:values).with_value(values)
      end

      it { expect(provider.values.frozen?).to be true }

      wrap_deferred 'when initialized with values: a Hash with String keys' do
        it { expect(provider.values).to eq(values) }

        it { expect(provider.values.frozen?).to be true }
      end

      wrap_deferred 'when initialized with values: a Hash with Symbol keys' do
        let(:expected_values) do
          {
            'env'        => 'test',
            'repository' => {
              'books' => []
            }
          }
        end

        it { expect(provider.values).to eq(expected_values) }

        it { expect(provider.values.frozen?).to be true }
      end
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with_unlimited_arguments
        .and_any_keywords
        .and_a_block
    end

    describe 'with parameters' do
      let(:arguments) { %w[ichi ni san] }
      let(:keywords)  { { ok: true } }
      let(:block)     { -> {} }

      it 'should raise an exception' do
        expect { described_class.new(*arguments, **keywords, &block) }
          .to raise_error ArgumentError
      end
    end

    wrap_deferred 'when the constructor takes parameters' do
      it { expect(instance.arguments).to be == [] }

      it { expect(instance.keywords).to be == {} }

      it { expect(instance.block).to be nil }

      describe 'with parameters' do
        let(:arguments) { %w[ichi ni san] }
        let(:keywords)  { { ok: true } }
        let(:block)     { -> {} }

        it { expect(instance.arguments).to be == arguments }

        it { expect(instance.keywords).to be == keywords }

        it { expect(instance.block).to be == block }
      end
    end

    wrap_deferred 'when the class defines dependencies' do
      describe 'with dependencies' do
        let(:dependencies) { { env: 'test', tools: Object.new } }

        it { expect(instance.env).to be dependencies[:env] }

        it { expect(instance.tools).to be dependencies[:tools] }
      end

      describe 'with parameters' do
        let(:arguments) { %w[ichi ni san] }
        let(:keywords)  { { ok: true } }
        let(:block)     { -> {} }

        it 'should raise an exception' do
          expect { described_class.new(*arguments, **keywords, &block) }
            .to raise_error ArgumentError
        end
      end
    end

    context 'when the constructor takes parameters and dependencies' do
      include_deferred 'when the constructor takes parameters'
      include_deferred 'when the class defines dependencies'

      it { expect(instance.arguments).to be == [] }

      it { expect(instance.keywords).to be == {} }

      it { expect(instance.block).to be nil }

      describe 'with dependencies' do
        let(:dependencies) { { env: 'test', tools: Object.new } }

        it { expect(instance.arguments).to be == [] }

        it { expect(instance.keywords).to be == {} }

        it { expect(instance.block).to be nil }

        it { expect(instance.env).to be dependencies[:env] }

        it { expect(instance.tools).to be dependencies[:tools] }
      end

      describe 'with parameters' do
        let(:arguments) { %w[ichi ni san] }
        let(:keywords)  { { ok: true } }
        let(:block)     { -> {} }

        it { expect(instance.arguments).to be == arguments }

        it { expect(instance.keywords).to be == keywords }

        it { expect(instance.block).to be == block }
      end

      describe 'with parameters and dependencies' do
        let(:arguments)    { %w[ichi ni san] }
        let(:keywords)     { { ok: true } }
        let(:block)        { -> {} }
        let(:dependencies) { { env: 'test', tools: Object.new } }

        it { expect(instance.arguments).to be == arguments }

        it { expect(instance.keywords).to be == keywords }

        it { expect(instance.block).to be == block }

        it { expect(instance.env).to be dependencies[:env] }

        it { expect(instance.tools).to be dependencies[:tools] }
      end
    end
  end

  describe '#plumbum_providers' do
    let(:parameters_provider) do
      an_instance_of(Plumbum::Parameters::Provider)
        .and(have_attributes(values: {}))
    end
    let(:expected_providers) { [parameters_provider] }

    it 'should return the providers' do
      expect(instance.plumbum_providers).to match_array(expected_providers)
    end

    wrap_deferred 'when the class includes providers' do
      let(:expected_providers) { [Spec::ConfigProvider, *super()] }

      it 'should return the providers' do
        expect(instance.plumbum_providers).to match_array(expected_providers)
      end
    end
  end
end
