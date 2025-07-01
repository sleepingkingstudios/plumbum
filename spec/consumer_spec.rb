# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum'

module Plumbum
  class Error < StandardError; end

  module Consumer
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    module ClassMethods
      def dependency(key)
        dependency_keys << key.to_s

        define_method(key) do
          plumbum_providers.each do |provider|
            return provider[key] if provider.key?(key)
          end

          raise Plumbum::Error, "missing dependency with key #{key.inspect}"
        end
      end

      def dependency_keys
        @dependency_keys ||= Set.new
      end

      def plumbum_class_providers
        @plumbum_class_providers ||=
          ancestors.select { |mod| mod.is_a? Plumbum::Provider }
      end
    end

    def initialize(...)
      super

      @plumbum_providers = [*self.class.plumbum_class_providers]
    end

    attr_reader :plumbum_providers
  end

  module Provider
    def [](key)
      values[key]
    end
    alias get []

    def fetch(key)
      values.fetch(key) do
        raise Plumbum::Error, "missing dependency with key #{key.inspect}"
      end
    end

    def has?(key)
      values.key?(key)
    end
    alias key? has?

    private

    def values
      @values ||= {}
    end
  end

  module Providers
    class HashProvider
      include Plumbum::Provider

      def initialize(**values)
        super()

        @values = values
      end
    end

    module Parameters
      class << self
        def partition_keywords(dependency_keys:, keywords:)
          dependencies = {}
          remainder    = {}

          keywords.each do |key, value|
            if dependency_keys.include?(key.to_s)
              dependencies[key.to_s] = value
            else
              remainder[key] = value
            end
          end

          [dependencies, remainder]
        end
      end

      def initialize(*, **keywords, &)
        dependencies, keywords =
          Plumbum::Providers::Parameters.partition_keywords(
            dependency_keys: self.class.dependency_keys,
            keywords:
          )

        super

        provider = Plumbum::Providers::HashProvider.new(**dependencies)

        @plumbum_providers.unshift(provider)
      end
    end

    class Singleton < Module
      include Plumbum::Provider

      UNDEFINED = Object.new.freeze

      def initialize(key, value = UNDEFINED)
        super()

        @key    = key
        @value  = value == UNDEFINED ? nil : value
        @values = value == UNDEFINED ? {} : { key => value }
      end

      attr_reader :key, :value

      def clear
        @value  = nil
        @values = {}
      end

      def value=(value)
        @value  = value
        @values = { key => value }
      end
    end
  end
end

SpaceProgram = Data.define(:name)

class SpaceProgram
  Provider = Plumbum::Providers::Singleton.new('space_program')
end

ToolsProvider = Plumbum::Providers::Singleton.new('tools')

class LaunchRocket
  include Plumbum::Consumer
  prepend Plumbum::Providers::Parameters
  include ToolsProvider
  include SpaceProgram::Provider

  dependency 'space_program'

  def initialize(launch_site:)
    super()

    @launch_site = launch_site
  end

  attr_reader :launch_site
end

RSpec.describe LaunchRocket do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:command) { described_class.new(launch_site:, **options) }

  let(:launch_site) { 'KSC' }
  let(:options)     { {} }

  describe '#launch_site' do
    it { expect(command.launch_site).to be == 'KSC' }
  end

  describe '#space_program' do
    let(:provider) { SpaceProgram::Provider }

    it { expect(command).to respond_to(:space_program).with(0).arguments }

    it 'should raise an exception' do
      expect { command.space_program }.to raise_error Plumbum::Error
    end

    context 'when initialized with space_program: value' do
      let(:space_program) { SpaceProgram.new('Morningstar Technologies') }
      let(:options)       { super().merge(space_program:) }

      it { expect(command.space_program).to be space_program }
    end

    context 'when the provider has a value' do
      before(:example) do
        provider.value = SpaceProgram.new(name: 'Avalon Heavy Industries')
      end

      after(:example) { provider.clear }

      it { expect(command.space_program).to be provider.value }

      context 'when initialized with space_program: value' do
        let(:space_program) { SpaceProgram.new('Morningstar Technologies') }
        let(:options)       { super().merge(space_program:) }

        it { expect(command.space_program).to be space_program }
      end
    end
  end
end
