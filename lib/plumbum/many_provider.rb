# frozen_string_literal: true

require 'plumbum'
require 'plumbum/providers/plural'

module Plumbum
  # Provider that provides a mapping of keys to values.
  class ManyProvider
    include Plumbum::Providers::Plural

    # @param values [Hash{String, Symbol => Object}] the provided values.
    # @param options [Hash] additional options for the provider.
    def initialize(values: Plumbum::UNDEFINED, **options)
      super()

      if values == Plumbum::UNDEFINED
        @values = values
      else
        validate_values(values)

        @values = values.transform_keys(&:to_s)
      end

      @options = validate_options(options)
    end

    # (see Plumbum::Providers::Plural#values)
    def values
      @values == Plumbum::UNDEFINED ? {} : super.dup
    end

    # @param values [Hash{String, Symbol => Object}] the updated values.
    def values=(values)
      validate_values(values)

      values = values.transform_keys(&:to_s)

      values.each_key { |key| require_mutable(key) }

      @values = values
    end

    private

    def get_value(key)
      value = super

      value == Plumbum::UNDEFINED ? nil : value
    end

    def has_value?(key) = super && @values[key] != Plumbum::UNDEFINED # rubocop:disable Naming/PredicatePrefix

    def validate_values(values)
      assertions = SleepingKingStudios::Tools::Toolbelt.instance.assertions

      assertions.validate_instance_of(values, as: :values, expected: Hash)

      values.each_key.with_index do |key, index|
        assertions.validate_name(key, as: :"values.keys[#{index}]")
      end
    end
  end
end
