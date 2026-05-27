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

      @values  = normalize_values(values)
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

      changed_values = find_changed_values(values)

      changed_values.each_key { |key| require_mutable(key) }

      @values = self.values.merge(changed_values)
    end

    private

    def find_changed_values(updated_values)
      missing_values = values.dup
      changed_values = updated_values.each.with_object({}) \
      do |(key, value), hsh|
        missing_values.delete(key)

        next if value == values[key]

        hsh[key] = value
      end

      missing_values.each_key { |key| changed_values[key] = Plumbum::UNDEFINED }

      changed_values
    end

    def get_value(key)
      value = super

      value == Plumbum::UNDEFINED ? nil : value
    end

    def has_value?(key, allow_undefined: false) # rubocop:disable Naming/PredicatePrefix
      super && (allow_undefined || @values[key] != Plumbum::UNDEFINED)
    end

    def normalize_values(values)
      return values if values == Plumbum::UNDEFINED

      if values.is_a?(Array)
        values = values.to_h { |key| [key, Plumbum::UNDEFINED] }
      end

      validate_values(values)

      @values = values.transform_keys(&:to_s)
    end

    def validate_values(values)
      tools.assertions.validate_instance_of(values, as: :values, expected: Hash)

      values.each_key.with_index do |key, index|
        tools.assertions.validate_name(key, as: :"values.keys[#{index}]")
      end
    end
  end
end
