# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::Consumer do
  subject(:consumer) { described_class.new }

  let(:described_class) { Spec::Consumer }
  let(:rocket)          { Spec::Rocket.new('Imp IV', false, false) }
  let(:rocket_provider) { Plumbum::OneProvider.new(:rocket, value: rocket) }

  example_constant 'Spec::Rocket' do
    Struct.new(:name, :fueled, :launched) do
      def launch = self.launched = true

      def refuel = self.fueled = true
    end
  end

  example_class 'Spec::Consumer' do |klass|
    klass.include Plumbum::Consumer # rubocop:disable RSpec/DescribedClass

    klass.provider rocket_provider

    klass.dependency 'rocket.#launch'

    klass.dependency '#refuel', scope: :rocket
  end

  describe '#launch' do
    it 'should delegate to the method' do
      expect { consumer.launch }
        .to change(rocket, :launched)
        .to be true
    end
  end

  describe '#refuel' do
    it 'should delegate to the method' do
      expect { consumer.refuel }
        .to change(rocket, :fueled)
        .to be true
    end
  end
end
