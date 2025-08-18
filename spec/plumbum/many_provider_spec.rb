# frozen_string_literal: true

require 'plumbum/many_provider'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::ManyProvider do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(**keywords) }

  deferred_context 'when initialized with values: UNDEFINED' do
    let(:values)   { Plumbum::UNDEFINED }
    let(:keywords) { super().merge(values:) }
  end

  deferred_context 'when initialized with values: an empty Hash' do
    let(:values)   { {} }
    let(:keywords) { super().merge(values:) }
  end

  deferred_context 'when initialized with values: an non-empty Hash' do
    let(:values)   { { 'option' => 'value', 'number' => 123 } }
    let(:keywords) { super().merge(values:) }
  end

  deferred_context 'when initialized with values: Hash with UNDEFINED values' do
    let(:values) do
      {
        'option' => 'value',
        'number' => 123,
        'color'  => Plumbum::UNDEFINED
      }
    end
    let(:keywords) { super().merge(values:) }
  end

  let(:options)     { {} }
  let(:keywords)    { options }
  let(:valid_keys)  { [] }
  let(:valid_pairs) { {} }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  include_deferred 'should implement the Provider interface'

  include_deferred 'should implement the plural Provider interface'

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
    wrap_deferred 'when initialized with values: UNDEFINED' do
      it { expect(provider.options).to be == options }
    end

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

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_deferred 'when initialized with values: UNDEFINED' do
      it { expect(provider.values).to be == {} }
    end

    wrap_deferred 'when initialized with values: an empty Hash' do
      it { expect(provider.values).to be == {} }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody

    context 'when initialized with values: a Hash with String keys' do
      let(:values)   { { 'option' => 'value', 'number' => 123 } }
      let(:keywords) { super().merge(values:) }

      it { expect(provider.values).to be == values }

      it 'should return a copy' do
        expect { provider.values.update('injected' => 'value') }
          .not_to change(provider, :values)
      end
    end

    context 'when initialized with values: a Hash with Symbol keys' do
      let(:values)   { { option: 'value', number: 123 } }
      let(:keywords) { super().merge(values:) }
      let(:expected) { values.transform_keys(&:to_s) }

      it { expect(provider.values).to be == expected }

      it 'should return a copy' do
        expect { provider.values.update('injected' => 'value') }
          .not_to change(provider, :values)
      end
    end

    wrap_deferred 'when initialized with values: Hash with UNDEFINED values' do
      it { expect(provider.values).to be == values }
    end
  end

  describe '#values=' do
    include_examples 'should define writer', :values=

    describe 'with nil' do
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
        expect { provider.values = nil }
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
        expect { provider.values = Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with nil keys' do
      let(:changed_values) do
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
        expect { provider.values = changed_values }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with Object keys' do
      let(:changed_values) do
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
        expect { provider.values = changed_values }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with empty String keys' do
      let(:changed_values) do
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
        expect { provider.values = changed_values }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with empty Symbol keys' do
      let(:changed_values) do
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
        expect { provider.values = changed_values }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with values: a Hash with String keys' do
      let(:changed_values) do
        {
          'color' => 'red',
          'shape' => 'circle'
        }
      end
      let(:error_message) do
        "unable to change immutable value for #{described_class} with key " \
          "#{changed_values.keys.first.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.values = changed_values }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    describe 'with values: a Hash with Symbol keys' do
      let(:changed_values) do
        {
          color: 'red',
          shape: 'circle'
        }
      end
      let(:error_message) do
        "unable to change immutable value for #{described_class} with key " \
          "#{changed_values.keys.first.to_s.inspect}"
      end

      it 'should raise an exception' do
        expect { provider.values = changed_values }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    context 'when initialized with read_only: false' do
      let(:options) { super().merge(read_only: false) }

      describe 'with values: a Hash with String keys' do
        let(:changed_values) do
          {
            'color' => 'red',
            'shape' => 'circle'
          }
        end

        it 'should update the values' do
          expect { provider.values = changed_values }
            .to change(provider, :values)
            .to be == changed_values.transform_keys(&:to_s)
        end
      end

      describe 'with values: a Hash with Symbol keys' do
        let(:changed_values) do
          {
            color: 'red',
            shape: 'circle'
          }
        end

        it 'should update the values' do
          expect { provider.values = changed_values }
            .to change(provider, :values)
            .to be == changed_values.transform_keys(&:to_s)
        end
      end

      # rubocop:disable RSpec/RepeatedExampleGroupBody
      wrap_deferred 'when initialized with values: an empty Hash' do
        describe 'with values: a Hash with String keys' do
          let(:changed_values) do
            {
              'color' => 'red',
              'shape' => 'circle'
            }
          end

          it 'should update the values' do
            expect { provider.values = changed_values }
              .to change(provider, :values)
              .to be == changed_values.transform_keys(&:to_s)
          end
        end

        describe 'with values: a Hash with Symbol keys' do
          let(:changed_values) do
            {
              color: 'red',
              shape: 'circle'
            }
          end

          it 'should update the values' do
            expect { provider.values = changed_values }
              .to change(provider, :values)
              .to be == changed_values.transform_keys(&:to_s)
          end
        end
      end

      wrap_deferred 'when initialized with values: an non-empty Hash' do
        describe 'with values: a Hash with String keys' do
          let(:changed_values) do
            {
              'color' => 'red',
              'shape' => 'circle'
            }
          end

          it 'should update the values' do
            expect { provider.values = changed_values }
              .to change(provider, :values)
              .to be == changed_values.transform_keys(&:to_s)
          end
        end

        describe 'with values: a Hash with Symbol keys' do
          let(:changed_values) do
            {
              color: 'red',
              shape: 'circle'
            }
          end

          it 'should update the values' do
            expect { provider.values = changed_values }
              .to change(provider, :values)
              .to be == changed_values.transform_keys(&:to_s)
          end
        end
      end
      # rubocop:enable RSpec/RepeatedExampleGroupBody

      context 'when the provider is frozen' do
        let(:error_message) do
          "can't modify frozen #{described_class}: #{provider.inspect}"
        end

        before(:example) { provider.freeze }

        it 'should raise an exception' do
          expect { provider.values = {} }
            .to raise_error FrozenError, error_message
        end
      end
    end
  end

  wrap_deferred 'when initialized with values: an empty Hash' do
    include_deferred 'should implement the Provider interface'
  end

  wrap_deferred 'when initialized with values: an non-empty Hash' do
    let(:valid_keys)  { values.keys }
    let(:valid_pairs) { values }

    include_deferred 'should implement the Provider interface'

    include_deferred 'should implement the plural Provider interface'
  end

  wrap_deferred 'when initialized with values: Hash with UNDEFINED values' do
    let(:invalid_key) { 'color' }
    let(:valid_keys)  { valid_pairs.keys }
    let(:valid_pairs) { values.except('color') }

    include_deferred 'should implement the Provider interface'

    include_deferred 'should implement the plural Provider interface'
  end
end
