# frozen_string_literal: true

require 'plumbum'
require 'plumbum/providers/plural'

module Plumbum
  # Provider that provides a mapping of keys to values.
  class ManyProvider
    include Plumbum::Providers::Plural

    # @param values [Hash{String, Symbol => Object}] the provided values.
    # @param options [Hash] additional options for the provider.
    def initialize(values: {}, **options)
      super()

      validate_values(values)

      @values  = values
      @options = options
    end

    # (see Plumbum::Providers::Plural#values)
    def values = super.dup

    private

    def validate_values(values)
      assertions = SleepingKingStudios::Tools::Toolbelt.instance.assertions

      assertions.validate_instance_of(values, as: :values, expected: Hash)

      values.each_key.with_index do |key, index|
        assertions.validate_name(key, as: :"values.keys[#{index}]")
      end
    end
  end
end
