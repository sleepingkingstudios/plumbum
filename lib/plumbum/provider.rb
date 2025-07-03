# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Abstract module defining the Provider interface.
  #
  # A Plumbum::Provider is responsible for making one or more values available
  # to a consumer object. How those values are stored or generated is up to the
  # provider implementation.
  #
  # Each provider implementation is responsible for defining the #get_value(key)
  # and #has_value(key) methods:
  #
  # - #get_value(key) must accept a single non-empty String argument and return
  #   the provided value matching the key, or nil if there is no matching value.
  # - #has_value?(key) must accept a single non-empty String argument and return
  #   true if the provider has a value matching the key, or false if there is
  #   no matching value.
  #
  # @see Plumbum::Consumer
  # @see Plumbum::Providers::Plural
  # @see Plumbum::Providers::Singular
  module Provider
    # Retrieves the provided value for the given key.
    #
    # @param key [String, Symbol] the key for the requested value.
    #
    # @return [Object, nil] the requested object, or nil if the provider does
    #   not have a value for the requested key.
    def get(key)
      key
        .then { |obj| normalize_key(obj) }
        .then { |str| get_value(str) }
    end

    # Checks if the provider has a value for the given key.
    #
    # @param key [String, Symbol] the key for the requested value.
    #
    # @return [true, false] true if the provider has a value for the requested
    #   key, otherwise false.
    def has?(key)
      key
        .then { |obj| normalize_key(obj) }
        .then { |str| has_value?(str) } # rubocop:disable Style/PreferredHashMethods
    end

    private

    def get_value(_key) = nil

    def has_value?(_key) = false # rubocop:disable Naming/PredicatePrefix

    def normalize_key(key)
      tools.assertions.validate_name(key, as: :key)

      key.to_s
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
