# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum do
  describe '::UNDEFINED' do
    it { expect(described_class).to have_constant(:UNDEFINED) }

    it { expect(described_class::UNDEFINED.class).to be Object }

    it { expect(described_class::UNDEFINED.frozen?).to be true }
  end

  describe '::VERSION' do
    it 'should define the constant' do
      expect(described_class)
        .to have_constant(:VERSION)
        .with_value(Plumbum::Version.to_gem_version)
    end
  end

  describe '.gem_path' do
    let(:expected) do
      sep = File::SEPARATOR

      __dir__.sub(/#{sep}spec#{sep}?\z/, '')
    end

    include_examples 'should define class reader',
      :gem_path,
      -> { eq(expected) }
  end

  describe '::version' do
    it 'should define the reader' do
      expect(described_class)
        .to have_reader(:version)
        .with_value(Plumbum::Version.to_gem_version)
    end
  end
end
