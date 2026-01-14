# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::Consumer do
  subject(:consumer) { described_class.new }

  let(:described_class) { Spec::Consumer }
  let(:provider_values) do
    {
      fuel_types:   %w[kerolox hydrolox],
      launch_sites: %w[KSC],
      messages:     {
        errors: {
          failure: 'not going to space'
        }
      },
      rockets:      {
        parts: {
          engines:    %w[small medium large],
          fuel_tanks: %w[short medium long]
        }
      }
    }
  end
  let(:planets) do
    {
      earth: Spec::Planet.new(name: 'The Earth', habitable: true),
      moon:  Spec::Planet.new(name: 'The Moon',  habitable: false)
    }
  end

  example_constant 'Spec::Planet' do
    Data.define(:name, :habitable)
  end

  example_constant 'Spec::PlanetsProvider' do
    Plumbum::ManyProvider.new(values: planets)
  end

  example_constant 'Spec::SpaceProvider' do
    Plumbum::ManyProvider.new(values: provider_values)
  end

  example_class 'Spec::Consumer' do |klass|
    klass.include Plumbum::Consumer # rubocop:disable RSpec/DescribedClass

    klass.provider Spec::PlanetsProvider
    klass.provider Spec::SpaceProvider

    klass.dependency :fuel_types, as: :fuel_options

    klass.dependency :launch_sites

    klass.dependency 'messages.errors.failure', as: :failure_message

    klass.dependency :earth, :moon

    klass.dependency :engines, :fuel_tanks, scope: 'rockets.parts'
  end

  describe '#earth' do
    it { expect(consumer.earth).to be == planets[:earth] }
  end

  describe '#engines' do
    let(:expected) { provider_values.dig(:rockets, :parts, :engines) }

    it { expect(consumer.engines).to be == expected }
  end

  describe '#failure_message' do
    let(:expected) { provider_values.dig(:messages, :errors, :failure) }

    it { expect(consumer.failure_message).to be == expected }
  end

  describe '#fuel_options' do
    it { expect(consumer.fuel_options).to be == provider_values[:fuel_types] }
  end

  describe '#fuel_tanks' do
    let(:expected) { provider_values.dig(:rockets, :parts, :fuel_tanks) }

    it { expect(consumer.fuel_tanks).to be == expected }
  end

  describe '#launch_sites' do
    it { expect(consumer.launch_sites).to be == provider_values[:launch_sites] }
  end

  describe '#moon' do
    it { expect(consumer.moon).to be == planets[:moon] }
  end
end
