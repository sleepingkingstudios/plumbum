# frozen_string_literal: true

require 'plumbum/many_provider'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::ManyProvider do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(**keywords) }

  deferred_context 'when initialized with values: an empty Hash' do
    let(:values)   { {} }
    let(:keywords) { super().merge(values:) }
  end

  deferred_context 'when initialized with values: an non-empty Hash' do
    let(:values)   { { 'option' => 'value', 'number' => 123 } }
    let(:keywords) { super().merge(values:) }
  end

  let(:options)  { {} }
  let(:keywords) { options }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  include_deferred 'should implement the Provider interface',
    has_valid_pairs: false

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).argument
        .and_keywords(:values)
        .and_any_keywords
    end

    describe 'with values: nil' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.instance_of',
            as:       :values,
            expected: Hash
          )
      end

      it 'should raise an exception' do
        expect { described_class.new(values: nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: an Object' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.instance_of',
            as:       :values,
            expected: Hash
          )
      end

      it 'should raise an exception' do
        expect { described_class.new(values: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with nil keys' do
      let(:values) do
        {
          'color' => 'red',
          nil     => 'value',
          shape:     'circle'
        }
      end
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.presence',
            as: :'values.keys[1]'
          )
      end

      it 'should raise an exception' do
        expect { described_class.new(values:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with Object keys' do
      let(:values) do
        {
          'color'           => 'red',
          Object.new.freeze => 'value',
          shape:               'circle'
        }
      end
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.name',
            as: :'values.keys[1]'
          )
      end

      it 'should raise an exception' do
        expect { described_class.new(values:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with empty String keys' do
      let(:values) do
        {
          'color' => 'red',
          ''      => 'value',
          shape:     'circle'
        }
      end
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.presence',
            as: :'values.keys[1]'
          )
      end

      it 'should raise an exception' do
        expect { described_class.new(values:) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with empty Symbol keys' do
      let(:values) do
        {
          'color' => 'red',
          :''     => 'value',
          shape:     'circle'
        }
      end
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.presence',
            as: :'values.keys[1]'
          )
      end

      it 'should raise an exception' do
        expect { described_class.new(values:) }
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '#options' do
    it { expect(provider.options).to be == options }

    context 'when initialized with options' do
      let(:options) { super().merge('custom_option' => 'custom value') }

      it { expect(provider.options).to be == options }
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_deferred 'when initialized with values: an empty Hash' do
      it { expect(provider.options).to be == options }
    end

    wrap_deferred 'when initialized with values: an non-empty Hash' do
      it { expect(provider.options).to be == options }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#values' do
    include_examples 'should define reader', :values, -> { {} }

    it 'should return a copy' do
      expect { provider.values.update('injected' => 'value') }
        .not_to change(provider, :values)
    end
  end

  wrap_deferred 'when initialized with values: an empty Hash' do
    include_deferred 'should implement the Provider interface',
      has_valid_pairs: false
  end

  wrap_deferred 'when initialized with values: an non-empty Hash' do
    let(:valid_pairs) { values }

    include_deferred 'should implement the Provider interface'
  end
end
