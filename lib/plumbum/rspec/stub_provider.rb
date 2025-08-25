# frozen_string_literal: true

require 'sleeping_king_studios/tools/toolbox/mixin'

require 'plumbum/rspec'

module Plumbum::RSpec
  # Helper methods for stubbing the values of Plumbum providers in RSpec tests.
  module StubProvider
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    # Class methods to extend when including StubProvider.
    module ClassMethods
      # (see Plumbum::RSpec::StubProvider#stub_provider)
      def stub_provider(provider, key, value)
        before(:example) { stub_provider(provider, key, value) }
      end
    end

    class << self
      # Verifies the provider has the given key.
      #
      # @param provider [Plumbum::Provider] the provider to stub.
      # @param key [String, Symbol] the key to verify.
      #
      # @return void
      #
      # @raise [ArgumentError] if the key is not a valid String or Symbol.
      # @raise [Plumbum::Errors::InvalidKeyError] if the key is not supported
      #   by the provider.
      def validate_key(provider, key)
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .validate_name(key, as: :key)

        return if provider.has?(key)

        return if provider.send(:raw_value, key.to_s) == Plumbum::UNDEFINED

        provider_name =
          provider.respond_to?(:name) ? provider.name : provider.class.name

        raise Plumbum::Errors::InvalidKeyError,
          "invalid key #{key.inspect} for #{provider_name}"
      end
    end

    # Stubs the value of a specific key for a provider for the current spec.
    #
    # @param provider [Plumbum::Provider] the provider to stub.
    # @param key [String, Symbol] the key to stub.
    # @param value [Object] the temporary value to assign for the key.
    #
    # @return [Symbol] the stubbed key.
    #
    # @raise [Plumbum::Errors::InvalidKeyError] if the key is not supported by
    #   the provider.
    def stub_provider(provider, key, value) # rubocop:disable Metrics/AbcSize
      StubProvider.validate_key(provider, key)

      unless RSpec::Mocks.space.registered?(provider)
        allow(provider).to receive(:get).and_call_original
        allow(provider).to receive(:has?).and_call_original
      end

      presence = value != Plumbum::UNDEFINED

      allow(provider).to receive(:get).with(key.to_s).and_return(value)
      allow(provider).to receive(:get).with(key.to_sym).and_return(value)
      allow(provider).to receive(:has?).with(key.to_s).and_return(presence)
      allow(provider).to receive(:has?).with(key.to_sym).and_return(presence)
    end
  end
end
