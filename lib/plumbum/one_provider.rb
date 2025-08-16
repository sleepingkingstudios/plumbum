# frozen_string_literal: true

require 'plumbum'
require 'plumbum/provider'
require 'plumbum/providers/singular'

module Plumbum
  # Provider that provides a single value for a specified key.
  class OneProvider
    include Plumbum::Providers::Singular

    UNDEFINED = Object.new.freeze
    private_constant :UNDEFINED

    # @param key [String, Symbol] the key used to identify the provided value.
    # @param value [Object] the provided value, if any.
    # @param options [Hash] additional options for the provider.
    def initialize(key, value: UNDEFINED, **options)
      super()

      SleepingKingStudios::Tools::Toolbelt
        .instance
        .assertions.validate_name(key, as: :key)

      @key     = key.to_s
      @value   = value
      @options = options
    end

    # @return [String, Symbol] the key used to identify the provided value.
    attr_reader :key

    # param [Object, nil] the provided value, or nil if the value is not
    #   defined.
    def value
      @value == UNDEFINED ? nil : @value
    end

    private

    def get_value(key)
      return nil if @value == UNDEFINED

      super
    end

    def has_value?(key) # rubocop:disable Naming/PredicatePrefix
      return false if @value == UNDEFINED

      super
    end
  end
end
