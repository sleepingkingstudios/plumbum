# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::ManyProvider do
  subject(:provider) { described_class.new(**options) }

  let(:options) { { write_once: true } }
  let(:values) do
    {
      'option' => 'original value',
      'hidden' => Plumbum::UNDEFINED
    }
  end

  describe '#get' do
    it { expect(provider.get('invalid')).to be nil }

    it { expect(provider.get('hidden')).to be nil }

    it { expect(provider.get('option')).to be nil }

    context 'when initialized with values' do
      let(:options) { super().merge(values:) }

      it { expect(provider.get('hidden')).to be nil }

      it { expect(provider.get('option')).to be == values['option'] }
    end
  end

  describe '#has?' do
    it { expect(provider.has?('invalid')).to be false }

    it { expect(provider.has?('hidden')).to be false }

    it { expect(provider.has?('hidden', allow_undefined: true)).to be false }

    it { expect(provider.has?('option')).to be false }

    context 'when initialized with values' do
      let(:options) { super().merge(values:) }

      it { expect(provider.has?('hidden')).to be false }

      it { expect(provider.has?('hidden', allow_undefined: true)).to be true }

      it { expect(provider.has?('option')).to be true }
    end
  end

  describe '#set' do
    let(:changed_value) { 'changed value' }

    describe 'with an invalid key' do
      let(:error_message) do
        'invalid key "invalid" for Plumbum::ManyProvider'
      end

      it 'should raise an exception' do
        expect { provider.set('invalid', changed_value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    describe 'with an uninitialized key' do
      let(:error_message) do
        'invalid key "hidden" for Plumbum::ManyProvider'
      end

      it 'should raise an exception' do
        expect { provider.set('hidden', changed_value) }
          .to raise_error Plumbum::Errors::InvalidKeyError, error_message
      end
    end

    context 'when initialized with values' do
      let(:options) { super().merge(values:) }

      describe 'with an invalid key' do
        let(:error_message) do
          'invalid key "invalid" for Plumbum::ManyProvider'
        end

        it 'should raise an exception' do
          expect { provider.set('invalid', changed_value) }
            .to raise_error Plumbum::Errors::InvalidKeyError, error_message
        end
      end

      describe 'with an uninitialized key' do
        it 'should update the value' do
          expect { provider.set('hidden', changed_value) }.to(
            change { provider.get('hidden') }.to(be == changed_value)
          )
        end
      end

      describe 'with a valid key' do
        let(:error_message) do
          'unable to change immutable value for Plumbum::ManyProvider with ' \
            'key "option"'
        end

        it 'should raise an exception' do
          expect { provider.set('option', changed_value) }
            .to raise_error Plumbum::Errors::ImmutableError, error_message
        end
      end
    end
  end

  describe '#values' do
    it { expect(provider.values).to be == {} }

    it 'should not change the values' do
      expect { provider.values['invalid'] = 'invalid value' }
        .not_to change(provider, :values)
    end

    context 'when initialized with values' do
      let(:options) { super().merge(values:) }

      it { expect(provider.values).to be == values }
    end
  end

  describe '#values=' do
    let(:changed_value) { { 'option' => 'changed value' } }

    it 'should update the values' do
      expect { provider.values = changed_value }.to(
        change(provider, :values).to(be == changed_value)
      )
    end

    context 'when initialized with values' do
      let(:options) { super().merge(values:) }
      let(:error_message) do
        'unable to change immutable value for Plumbum::ManyProvider with ' \
          'key "option"'
      end

      it 'should raise an exception' do
        expect { provider.values = changed_value }
          .to raise_error Plumbum::Errors::ImmutableError, error_message
      end
    end
  end
end
