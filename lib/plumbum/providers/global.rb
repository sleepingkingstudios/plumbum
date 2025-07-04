# frozen_string_literal: true

require 'plumbum/providers'

module Plumbum::Providers
  # Provider that wraps a single value scoped to the current process.
  #
  # By default, the value is immutable, but setting the value can be deferred
  # after initializing the provider. If any :value is passed to the constructor,
  # even nil, then calling #value= will raise an ImmutableError unless the
  # :mutable flag was set to true. However, if no :value is passed to the
  # constructor, the provider value can be set once using the #value= writer
  # method.
  class Global < Module
    include Plumbum::Providers::Singular

    UNDEFINED = Object.new.freeze
    private_constant :UNDEFINED

    # @overload initialize(key:, value: nil, mutable: false)
    #   @param key [String, Symbol] the key of the scoped value.
    #   @param value [Object] the value for the provider.
    #   @param mutable [true, false] if true, allows the value to be updated
    #     once it has been set. Defaults to false.
    def initialize(key:, mutable: false, value: UNDEFINED)
      super()

      tools.assertions.validate_name(key, as: :key)

      @key     = key
      @value   = value
      @mutable = !!mutable
    end

    # @return [true, false] if true, allows the value to be updated once it has
    #   been set. Defaults to false.
    def mutable?
      @mutable
    end

    # @return [Object] the value returned by the provider.
    def value
      @value == UNDEFINED ? nil : @value
    end

    # Sets the value for the provider.
    #
    # If the value has already been set (even to nil), and the #mutable? flag is
    # false, this method will raise an exception.
    #
    # @param value [Object] the value for the provider.
    def value=(value)
      if @value != UNDEFINED && !mutable?
        raise Plumbum::Errors::ImmutableError,
          "unable to change immutable value for #{self.class.name} with key " \
          "#{key.inspect}"
      end

      @value = value
    end

    private

    def get_value(key) = @value == UNDEFINED ? nil : super

    def has_value?(key) = @value != UNDEFINED && super # rubocop:disable Naming/PredicatePrefix
  end
end
