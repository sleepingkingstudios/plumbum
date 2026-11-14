# frozen_string_literal: true

require 'plumbum/dependencies/clock/mock'

RSpec.describe Plumbum::Dependencies::Clock::Mock do
  subject(:mock_clock) { described_class.new(**constructor_options) }

  let(:constructor_options)  { {} }
  let(:default_current_time) { Time.now(in: 'Z') - 3_600 }
  let(:default_monotonic_time) do
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - 3_600.0
  end

  before(:example) do
    allow(Process).to receive(:clock_gettime).and_return(default_monotonic_time)
    allow(Time).to receive(:now).and_return(default_current_time)

    mock_clock

    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Time).to receive(:now).and_call_original
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:current_time, :monotonic_time)
    end
  end

  describe '#get_monotonic_time' do
    it { expect(mock_clock.get_monotonic_time).to be default_monotonic_time }

    context 'when initialized with monotonic_time: value' do
      let(:monotonic_time)      { default_monotonic_time + 1_000.0 }
      let(:constructor_options) { super().merge(monotonic_time:) }

      it { expect(mock_clock.get_monotonic_time).to be monotonic_time }
    end
  end

  describe '#get_time' do
    it 'should define the aliased method' do
      expect(mock_clock).to have_aliased_method(:get_time).as(:current_time)
    end

    it { expect(mock_clock).to have_aliased_method(:get_time).as(:now) }

    it { expect(mock_clock.get_time).to be default_current_time }

    context 'when initialized with current_time: value' do
      let(:current_time)        { default_current_time + 1_000 }
      let(:constructor_options) { super().merge(current_time:) }

      it { expect(mock_clock.get_time).to be current_time }
    end
  end

  describe '#measure' do
    it { expect(mock_clock.measure { nil }).to be 0.0 }
  end
end
