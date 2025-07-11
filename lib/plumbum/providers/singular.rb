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

    def get_value(key) = key == self.key ? value : nil

    def has_value?(key) = key == self.key # rubocop:disable Naming/PredicatePrefix
  end
end
