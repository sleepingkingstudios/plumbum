# frozen_string_literal: true

require 'plumbum/providers'

module Plumbum::Providers
  # Provider implementation that wraps a single key-value pair.
  module Singular
    include Plumbum::Provider

    # @return [String] the key matched by the provider.
    attr_reader :key

    # @return [Object] the value returned by the provider.
    attr_reader :value

    private

    def has_value?(key) = key == self.key # rubocop:disable Naming/PredicatePrefix

    def raw_value(key) = key == self.key ? @value : nil

    def set_value(key, value) = key == self.key ? @value = value : nil

    def valid_key?(key) = key == self.key
  end
end
