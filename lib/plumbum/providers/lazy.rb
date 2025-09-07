# frozen_string_literal: true

require 'plumbum/providers'

module Plumbum::Providers
  # Provider that calls proc values and returns the result.
  #
  # Add Plumbum::Providers::Lazy for values that have a consistent definition
  # but changing value, such as class definitions under code reloading.
  module Lazy
    # Retrieves the provided value for the given key.
    #
    # If the value is a Proc, the Proc is called and the value returned by the
    # Proc is returned by #get. Otherwise, #get returns the value directly.
    #
    # @param key [String, Symbol] the key for the requested value.
    #
    # @return [Object, nil] the requested object, or nil if the provider does
    #   not have a value for the requested key.
    def get(key)
      value = super

      value.is_a?(Proc) ? value.call : value
    end
  end
end
