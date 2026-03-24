# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum/consumers'

module Plumbum::Consumers
  # Instance methods for defining the Consumer interface.
  module InstanceMethods
    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED

    # Retrieves the dependency with the specified key.
    #
    # @param key [String, Symbol] the key for the requested dependency.
    # @param optional [true, false] if true, returns nil if the dependency is
    #   not defined. Defaults to false.
    #
    # @return [Object] the dependency value.
    #
    # @raise [ArgumentError] if the key is not a String or Symbol, or is empty.
    # @raise [Plumbum::Errors::MissingDependencyError] if no matching dependency
    #   is found.
    def get_plumbum_dependency(key, optional: false)
      SleepingKingStudios::Tools::Toolbelt
        .instance
        .assertions
        .validate_name(key, as: :key)

      find_plumbum_dependency(key) do
        handle_missing_plumbum_dependency(key, optional:)
      end
    end

    # Checks if the dependency with the given key is defined.
    #
    # @param key [String, Symbol] the key for the requested dependency.
    #
    # @return [true, false] true if the dependency is defined, otherwise false.
    #
    # @raise [ArgumentError] if the key is not a String or Symbol, or is empty.
    def has_plumbum_dependency?(key) # rubocop:disable Naming/PredicatePrefix
      SleepingKingStudios::Tools::Toolbelt
        .instance
        .assertions
        .validate_name(key, as: :key)

      find_plumbum_dependency(key) { return false }

      true
    end

    private

    def find_plumbum_dependency(key)
      plumbum_providers.each do |provider|
        return provider.get(key) if provider.has?(key)
      end

      yield
    end

    def get_scoped_plumbum_dependency( # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      key,
      path:,
      default:  UNDEFINED,
      optional: false
    )
      optional ||= default != UNDEFINED
      dependency = get_plumbum_dependency(key, optional:)

      if dependency.nil?
        return if default == UNDEFINED

        return default unless default.is_a?(Proc)

        return instance_exec(&default)
      end

      return dependency if path.nil? || path.empty?

      path.reduce(dependency) do |memo, method_name|
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .object_tools
          .fetch(memo, method_name, indifferent_key: true)
      end
    rescue KeyError, IndexError, NoMethodError => exception # rubocop:disable Lint/ShadowedException
      raise Plumbum::Errors::MissingDependencyError,
        exception.message,
        cause: exception
    end

    def handle_missing_plumbum_dependency(key, optional: false)
      return nil if optional

      raise Plumbum::Errors::MissingDependencyError,
        "dependency not found with key #{key.inspect}"
    end

    def plumbum_providers
      self.class.plumbum_providers
    end
  end
end
