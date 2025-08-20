# frozen_string_literal: true

require 'plumbum/providers'

module Plumbum::Providers
  # Provider implementation that wraps a multiple key-value pairs.
  module Plural
    include Plumbum::Provider

    # @return [Hash] the key-value pairs returned by the provider.
    attr_reader :values

    private

    def get_value(key) = values[key]

    def has_value?(key) = values.key?(key) # rubocop:disable Naming/PredicatePrefix

    def mutable?(key)
      return true if write_once? && @values == Plumbum::UNDEFINED

      super
    end

    def raw_value(key) = values[key]

    def set_value(key, value)
      @values[key.to_s] = value
    end
  end
end
