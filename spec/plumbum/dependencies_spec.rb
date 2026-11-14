# frozen_string_literal: true

require 'plumbum/dependencies'

RSpec.describe Plumbum::Dependencies do
  describe '.provider' do
    let(:provider) { described_class.provider }

    include_examples 'should define class reader',
      :provider,
      -> { be_a Plumbum::ManyProvider }

    it 'should memoize the value' do
      expect(provider).to be described_class.provider
    end

    it 'should provide a Clock dependency' do
      expect(provider.get(:clock)).to be_a described_class::Clock
    end

    it 'should provide a FileSystem dependency' do
      expect(provider.get(:file_system)).to be_a described_class::FileSystem
    end

    it 'should provide a StandardIo dependency' do
      expect(provider.get(:standard_io)).to be_a described_class::StandardIo
    end

    it 'should provide a SystemCommand dependency' do
      expect(provider.get(:system_command))
        .to be_a described_class::SystemCommand
    end
  end
end
