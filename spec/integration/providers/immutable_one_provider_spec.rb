# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::OneProvider do
  subject(:provider) { described_class.new('option', **options) }

  let(:options) { {} }

  describe '#get' do
    it { expect(provider.get('invalid')).to be nil }

    it { expect(provider.get('option')).to be nil }

    context 'when initialized with a value' do
      let(:value)   { 'original value' }
      let(:options) { super().merge(value:) }

      it { expect(provider.get('option')).to be == value }
    end
  end

  describe '#has?' do
    it { expect(provider.has?('invalid')).to be false }

    it { expect(provider.has?('option')).to be false }

    it { expect(provider.has?('option', allow_undefined: true)).to be true }

    context 'when initialized with a value' do
      let(:value)   { 'original value' }
      let(:options) { super().merge(value:) }

      it { expect(provider.has?('option')).to be true }
    end
  end

  describe '#key' do
    it { expect(provider.key).to be == 'option' }
  end

  describe '#set' do
    let(:changed_value) { 'changed value' }

    describe 'with an invalid key' do
      let(:error_message) do
        'invalid key "invalid" for Plumbum::OneProvider'
      end

      it 'should raise an exception' do
        expect { provider.set('invalid', changed_value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with a valid key' do
      let(:error_message) do
        'unable to change immutable value for Plumbum::OneProvider with key ' \
          '"option"'
      end

      it 'should raise an exception' do
        expect { provider.set('option', changed_value) }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end

    context 'when initialized with a value' do
      let(:value)   { 'original value' }
      let(:options) { super().merge(value:) }

      describe 'with an invalid key' do
        let(:error_message) do
          'invalid key "invalid" for Plumbum::OneProvider'
        end

        it 'should raise an exception' do
          expect { provider.set('invalid', changed_value) }
            .to raise_error Plumbum::Errors::InvalidKeyError, error_message
        end
      end

      describe 'with a valid key' do
        let(:error_message) do
          'unable to change immutable value for Plumbum::OneProvider with ' \
            'key "option"'
        end

        it 'should raise an exception' do
          expect { provider.set('option', changed_value) }
            .to raise_error Plumbum::Errors::ImmutableError, error_message
        end
      end
    end
  end

  describe '#value' do
    it { expect(provider.value).to be nil }

    context 'when initialized with a value' do
      let(:value)   { 'original value' }
      let(:options) { super().merge(value:) }

      it { expect(provider.value).to be == value }
    end
  end

  describe '#value=' do
    let(:changed_value) { 'changed value' }
    let(:error_message) do
      'unable to change immutable value for Plumbum::OneProvider with ' \
        'key "option"'
    end

    it 'should raise an exception' do
      expect { provider.value = changed_value }
        .to raise_error Plumbum::Errors::ImmutableError, error_message
    end

    context 'when initialized with a value' do
      let(:value)   { 'original value' }
      let(:options) { super().merge(value:) }

      it 'should raise an exception' do
        expect { provider.value = changed_value }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end
  end
end
