# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::Consumer do
  subject(:consumer) { described_class.new }

  let(:described_class) { Spec::Consumer }

  example_constant 'Spec::IncludedProvider' do
    Plumbum::OneProvider.new(:included_value, value: 'included value')
  end

  example_constant 'Spec::IncludedConsumer' do
    Module.new do
      include Plumbum::Consumer

      provider Spec::IncludedProvider

      dependency :included_value
    end
  end

  example_class 'Spec::Consumer' do |klass|
    klass.include Spec::IncludedConsumer
  end

  describe '#included_value' do
    it { expect(consumer.included_value).to be == Spec::IncludedProvider.value }
  end
end
