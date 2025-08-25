# frozen_string_literal: true

require 'plumbum/rspec/stub_provider'

RSpec.describe Plumbum::RSpec::StubProvider do
  deferred_examples 'should stub the provider value' do
    it 'should not change provider.get for other keys', :aggregate_failures do
      stub_provider(provider, key, value)

      expect(provider.get('invalid')).to be nil
      expect(provider.get(:invalid)).to be nil
      expect(provider.get('secret')).to be provider.values['secret']
      expect(provider.get(:secret)).to be provider.values['secret']
    end

    it 'should not change provider.has? for other keys', :aggregate_failures do
      stub_provider(provider, key, value)

      expect(provider.has?('invalid')).to be false
      expect(provider.has?(:invalid)).to be false
      expect(provider.has?('secret')).to be true
      expect(provider.has?(:secret)).to be true
    end

    it 'should stub provider.get for the key', :aggregate_failures do
      stub_provider(provider, key, value)

      expect(provider.get(key.to_s)).to be value
      expect(provider.get(key.to_sym)).to be value
    end

    it 'should stub provider.has? for the key', :aggregate_failures do
      stub_provider(provider, key, value)

      expect(provider.has?(key.to_s)).to be value != Plumbum::UNDEFINED
      expect(provider.has?(key.to_sym)).to be value != Plumbum::UNDEFINED
    end
  end

  let(:example_group) { self.class }
  let(:example)       { self }
  let(:values) do
    {
      custom: 'custom value',
      option: 'option value',
      secret: 'secret value'
    }
  end
  let(:provider) do
    Plumbum::ManyProvider.new(values:)
  end

  define_method(:tools) do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  describe '.stub_provider' do
    include Plumbum::RSpec::StubProvider # rubocop:disable RSpec/DescribedClass

    let(:key)   { 'option' }
    let(:value) { Object.new.freeze }

    example_constant 'Spec::ExampleProvider' do
      provider
    end

    before(:example) do
      allow(example).to receive(:stub_provider)
    end

    it { expect(example_group).to respond_to(:stub_provider).with(3).arguments }

    it 'should set a before hook' do
      allow(example_group).to receive(:before)

      example_group.stub_provider(Spec::ExampleProvider, key, value)

      expect(example_group).to have_received(:before).with(:example)
    end

    it 'should delegate to the example' do
      hook = nil

      allow(example_group).to receive(:before) { |_, &block| hook = block }

      example_group.stub_provider(Spec::ExampleProvider, key, value)

      instance_exec(&hook)

      expect(example)
        .to have_received(:stub_provider)
        .with(provider, key, value)
    end
  end

  describe '#stub_provider' do
    include Plumbum::RSpec::StubProvider # rubocop:disable RSpec/DescribedClass

    let(:key)   { 'option' }
    let(:value) { Object.new.freeze }

    it { expect(example).to respond_to(:stub_provider).with(3).arguments }

    describe 'with key: nil' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.presence',
            as: :key
          )
      end

      it 'should raise an exception' do
        expect { example.stub_provider(provider, nil, value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with key: an Object' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.name',
            as: :key
          )
      end

      it 'should raise an exception' do
        expect { example.stub_provider(provider, Object.new.freeze, value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with key: an empty String' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.presence',
            as: :key
          )
      end

      it 'should raise an exception' do
        expect { example.stub_provider(provider, '', value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with key: an empty Symbol' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.presence',
            as: :key
          )
      end

      it 'should raise an exception' do
        expect { example.stub_provider(provider, :'', value) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with key: an invalid String' do
      let(:key) { 'invalid' }
      let(:error_message) do
        "invalid key #{key.inspect} for #{provider.class.name}"
      end

      it 'should raise an exception' do
        expect { example.stub_provider(provider, key, value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with key: an invalid Symbol' do
      let(:key) { :invalid }
      let(:error_message) do
        "invalid key #{key.inspect} for #{provider.class.name}"
      end

      it 'should raise an exception' do
        expect { example.stub_provider(provider, key, value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with key: a valid String' do
      let(:key) { 'option' }

      include_deferred 'should stub the provider value'

      describe 'with value: undefined' do
        let(:value) { Plumbum::UNDEFINED }

        include_deferred 'should stub the provider value'
      end

      context 'when the existing value is undefined' do
        context 'with a plural provider' do
          let(:values) { super().merge(option: Plumbum::UNDEFINED) }

          include_deferred 'should stub the provider value'
        end

        context 'with a singular provider' do
          let(:value)    { Plumbum::UNDEFINED }
          let(:provider) { Plumbum::OneProvider.new(key, value:) }

          it 'should stub provider.get for the key', :aggregate_failures do
            stub_provider(provider, key, value)

            expect(provider.get(key.to_s)).to be value
            expect(provider.get(key.to_sym)).to be value
          end

          it 'should stub provider.has? for the key', :aggregate_failures do
            stub_provider(provider, key, value)

            expect(provider.has?(key.to_s)).to be value != Plumbum::UNDEFINED
            expect(provider.has?(key.to_sym)).to be value != Plumbum::UNDEFINED
          end
        end
      end
    end

    describe 'with key: a valid Symbol' do
      let(:key) { :option }

      include_deferred 'should stub the provider value'

      describe 'with value: undefined' do
        let(:value) { Plumbum::UNDEFINED }

        include_deferred 'should stub the provider value'
      end

      context 'when the existing value is undefined' do
        context 'with a plural provider' do
          let(:values) { super().merge(option: Plumbum::UNDEFINED) }

          include_deferred 'should stub the provider value'
        end

        context 'with a singular provider' do
          let(:value)    { Plumbum::UNDEFINED }
          let(:provider) { Plumbum::OneProvider.new(key, value:) }

          it 'should stub provider.get for the key', :aggregate_failures do
            stub_provider(provider, key, value)

            expect(provider.get(key.to_s)).to be value
            expect(provider.get(key.to_sym)).to be value
          end

          it 'should stub provider.has? for the key', :aggregate_failures do
            stub_provider(provider, key, value)

            expect(provider.has?(key.to_s)).to be value != Plumbum::UNDEFINED
            expect(provider.has?(key.to_sym)).to be value != Plumbum::UNDEFINED
          end
        end
      end
    end

    context 'when the provider has multiple stubbed keys' do
      let(:custom_value) { Object.new.freeze }

      before(:example) do
        stub_provider(provider, 'custom', custom_value)
      end

      describe 'with key: a valid String' do
        let(:key) { 'option' }

        include_deferred 'should stub the provider value'

        it 'should not overwrite existing stubs', :aggregate_failures do
          stub_provider(provider, key, value)

          expect(provider.get('custom')).to be custom_value
          expect(provider.has?('custom')).to be true
        end
      end

      describe 'with key: a valid Symbol' do
        let(:key) { :option }

        include_deferred 'should stub the provider value'

        it 'should not overwrite existing stubs', :aggregate_failures do
          stub_provider(provider, key, value)

          expect(provider.get('custom')).to be custom_value
          expect(provider.has?('custom')).to be true
        end
      end
    end
  end
end
