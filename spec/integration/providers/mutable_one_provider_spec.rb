# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::OneProvider do
  subject(:provider) { described_class.new('option', **options) }

  let(:options) { { read_only: false } }

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
      it 'should update the value' do
        expect { provider.set('option', changed_value) }.to(
          change { provider.get('option') }.to(be == changed_value)
        )
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
        it 'should update the value' do
          expect { provider.set('option', changed_value) }.to(
            change { provider.get('option') }.to(be == changed_value)
          )
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

    it 'should update the value' do
      expect { provider.value = changed_value }.to(
        change { provider.get('option') }.to(be == changed_value)
      )
    end

    context 'when initialized with a value' do
      let(:value)   { 'original value' }
      let(:options) { super().merge(value:) }

      it 'should update the value' do
        expect { provider.value = changed_value }.to(
          change { provider.get('option') }.to(be == changed_value)
        )
      end
    end
  end
end
