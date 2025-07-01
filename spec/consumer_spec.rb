# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum'

module Plumbum
  class Error < StandardError; end

  module Consumer
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    module ClassMethods
      def dependency(key)
        define_method(key) do
          plumbum_providers.each do |provider|
            return provider[key] if provider.key?(key)
          end

          raise Plumbum::Error, "missing dependency with key #{key.inspect}"
        end
      end
    end

    def initialize(...)
      super

      @plumbum_providers =
        self.class.ancestors.select { |mod| mod.is_a? Plumbum::Provider }
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

class LaunchRocket
  include Plumbum::Consumer
  include SpaceProgram::Provider

  dependency 'space_program'
end

RSpec.describe LaunchRocket do # rubocop:disable RSpec/SpecFilePathFormat
  subject(:command) { described_class.new }

  describe '#space_program' do
    let(:provider) { SpaceProgram::Provider }

    it { expect(command).to respond_to(:space_program).with(0).arguments }

    it 'should raise an exception' do
      expect { command.space_program }.to raise_error Plumbum::Error
    end

    context 'when the provider has a value' do
      before(:example) do
        provider.value = SpaceProgram.new(name: 'Avalon Heavy Industries')
      end

      after(:example) { provider.clear }

      it { expect(command.space_program).to be provider.value }
    end
  end
end
