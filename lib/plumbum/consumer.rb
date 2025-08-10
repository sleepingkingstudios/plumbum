# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum'

module Plumbum
  # Provides methods for defining and accessing injected dependencies.
  module Consumer
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    # Class methods to extend when including Plumbum::Consumer.
    module ClassMethods
      # Defines an injected dependency for instances of the class.
      #
      # @param key [String, Symbol] the key for the dependency.
      # @param as [String, Symbol] the method name used to define dependency
      #   methods. Defaults to the key.
      # @param optional [true, false] if true, calling the dependency returns
      #   nil if the dependency is not defined. Defaults to false.
      # @param predicate [true, false] if true, also defines a predicate method
      #   that returns true if the dependency has a defined value. Defaults to
      #   false.
      #
      # @return [Symbol] the name of the generated method.
      #
      # @raise [ArgumentError] if the key is not a String or Symbol, or is
      #   empty.
      def dependency(key, as: nil, optional: false, predicate: false)
        validate_name(key, as: :key)
        validate_name(as,  as: :as) unless as.nil?

        dependency_keys << key.to_s

        define_predicate(key, as:) if predicate

        define_reader(key, as:, optional:)
      end

      # @return [Set<String>] the keys of the dependencies declared by the class
      #   and its ancestors.
      def dependency_keys
        return @dependency_keys if @dependency_keys

        @dependency_keys =
          if superclass < Plumbum::Consumer
            superclass.dependency_keys.dup
          else
            Set.new
          end
      end

      # @return [Array<Plumbum::Provider>] the providers defined for the class.
      def plumbum_providers
        @plumbum_providers ||=
          ancestors
          .select { |mod| mod.is_a?(Plumbum::Provider) }
      end

      private

      def define_predicate(key, as: nil)
        method_name = :"#{as || key}?"

        dependency_methods.define_method(method_name) do
          has_plumbum_dependency?(key)
        end
      end

      def define_reader(key, as: nil, optional: false)
        method_name = as || key

        dependency_methods.define_method(method_name) do
          get_plumbum_dependency(key, optional:)
        end
      end

      def dependency_methods
        if const_defined?(:DependencyMethods, false)
          return const_get(:DependencyMethods)
        end

        Module
          .new
          .tap { |mod| include mod }
          .then { |mod| const_set(:DependencyMethods, mod) }
      end

      def validate_name(value, as: nil)
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .validate_name(value, as:)
      end
    end

    # @return a new instance of Consumer.
    def initialize(...)
      super

      @plumbum_providers = self.class.plumbum_providers
    end

    # @return [Array<Plumbum::Provider>] the providers defined for the instance.
    attr_reader :plumbum_providers

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
        .assertions.validate_name(key, as: :key)

      find_dependency(key) do
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
        .assertions.validate_name(key, as: :key)

      find_dependency(key) { return false }

      true
    end

    private

    def find_dependency(key)
      plumbum_providers.each do |provider|
        return provider.get(key) if provider.has?(key)
      end

      yield
    end

    def handle_missing_plumbum_dependency(key, optional: false)
      return nil if optional

      raise Plumbum::Errors::MissingDependencyError,
        "dependency not found with key #{key.inspect}"
    end
  end
end
