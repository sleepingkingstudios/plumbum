# frozen_string_literal: true

require 'plumbum/dependencies/clock'

RSpec.describe Plumbum::Dependencies::Clock do
  subject(:clock) { described_class.new }

  describe '#get_monotonic_time' do
    let(:current_time) { Process.clock_gettime(Process::CLOCK_MONOTONIC) }

    before(:example) do
      allow(Process).to receive(:clock_gettime).and_return(current_time)
    end

    it { expect(clock).to respond_to(:get_monotonic_time).with(0).arguments }

    it { expect(clock.get_monotonic_time).to eq current_time }
  end

  describe '#get_time' do
    let(:current_time) { Time.now(in: 'Z').to_i }

    before(:example) do
      allow(Time)
        .to receive(:now)
        .with(in: 'Z')
        .and_return(Time.now(in: 'Z'))
    end

    it { expect(clock).to respond_to(:get_time).with(0).arguments }

    it { expect(clock).to have_aliased_method(:get_time).as(:current_time) }

    it { expect(clock).to have_aliased_method(:get_time).as(:now) }

    it { expect(clock.get_time).to be_a Time }

    it { expect(clock.get_time.to_i).to be == current_time }

    it { expect(clock.get_time.zone).to eq 'UTC' }
  end

  describe '#measure' do
    let(:start_time) { Process.clock_gettime(Process::CLOCK_MONOTONIC) }
    let(:end_time)   { start_time + 10.0 }

    before(:example) do
      allow(Process)
        .to receive(:clock_gettime)
        .and_return(start_time, end_time)
    end

    it { expect(clock).to respond_to(:measure).with(0).arguments }

    describe 'without a block' do
      let(:error_message) { 'no block given (yield)' }

      it 'should raise an exception' do
        expect { clock.measure }.to raise_error LocalJumpError, error_message
      end
    end

    describe 'with a block' do
      it 'should call the block' do
        expect { |block| clock.measure(&block) }.to yield_control
      end

      it 'should measure the elapsed time' do
        expect(clock.measure { nil })
          .to be_within(0.1).of(end_time - start_time)
      end
    end
  end
end
