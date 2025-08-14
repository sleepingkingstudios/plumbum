# frozen_string_literal: true

require 'plumbum'
require 'plumbum/errors/immutable_error'
require 'plumbum/errors/invalid_key_error'

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

    # Sets the value for the given key.
    #
    # @param key [String, Symbol] the key for the assigned value.
    # @param value [Object] the value to assign.
    #
    # @return [Object] the assigned value.
    #
    # @raise [Plumbum::Errors::ImmutableError] when attempting to assign a value
    #   to an immutable provider.
    def set(key, value)
      key
        .then { |obj| normalize_key(obj) }
        .tap  { |key| validate_key(key) }
        .tap  { |key| require_mutable(key) }
        .then { |key| set_value(key, value) }
    end

    # @return Hash{Symbol => Object} the options used to configure the provider.
    def options
      @options ||= {}
    end

    private

    def get_value(_key) = nil

    def has_value?(_key) = false # rubocop:disable Naming/PredicatePrefix

    def set_value(_key, _value) = nil

    def mutable?(_key) = false

    def normalize_key(key)
      tools.assertions.validate_name(key, as: :key)

      key.to_s
    end

    def provider_name = respond_to?(:name) ? name : self.class.name

    def require_mutable(key)
      return if mutable?(key)

      raise Plumbum::Errors::ImmutableError,
        "unable to change immutable value for #{provider_name} with key " \
        "#{key.inspect}"
    end

    def tools = SleepingKingStudios::Tools::Toolbelt.instance

    def valid_key?(key) = has_value?(key) # rubocop:disable Style/PreferredHashMethods

    def validate_key(key)
      return if valid_key?(key)

      raise Plumbum::Errors::InvalidKeyError,
        "invalid key #{key.inspect} for #{provider_name}"
    end
  end
end
