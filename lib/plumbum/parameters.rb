# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Utility module that converts constructor parameters to a Provider.
  module Parameters
    # Provider that wraps a subset of the constructor parameters.
    class Provider
      include Plumbum::Providers::Plural

      UNDEFINED = Object.new.freeze
      private_constant :UNDEFINED

      # @param values [Hash{Symbol=>Object}] the key-value pairs returned by the
      #   provider.
      def initialize(values: UNDEFINED)
        values = {} if values == UNDEFINED

        validate_values(values)

        @values =
          values
          .transform_keys(&:to_s)
          .freeze
      end

      private

      def validate_values(values)
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .validate_instance_of(values, expected: Hash, as: 'values')
      end
    end

    # @overload initialize(*arguments, **keywords, &block)
    #   @param arguments [Array] the arguments passed to the constructor.
    #   @param keywords [Hash] the keywords passed to the constructor, including
    #     any injected dependencies.
    #   @param block [Proc] the block passed to the constructor.
    def initialize(*, **keywords, &)
      values, keywords = extract_plumbum_dependencies(keywords)

      super

      @plumbum_parameters_provider = Plumbum::Parameters::Provider.new(values:)
    end

    private

    def extract_plumbum_dependencies(keywords)
      dependency_keys = self.class.dependency_keys

      keywords
        .partition { |key, _| dependency_keys.include?(key.to_s) }
        .map(&:to_h)
    end

    def plumbum_providers
      [
        @plumbum_parameters_provider,
        *super
      ]
    end
  end
end
