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
      #
      # @return [Symbol] the name of the generated method.
      def dependency(key)
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .validate_name(key, as: :key)

        dependency_keys << key.to_s

        define_reader(key)
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

      def define_reader(key)
        dependency_methods =
          if const_defined?(:DependencyMethods, false)
            const_get(:DependencyMethods)
          else
            Module
              .new
              .tap { |mod| include mod }
              .then { |mod| const_set(:DependencyMethods, mod) }
          end

        dependency_methods.define_method(key) { get_plumbum_dependency(key) }
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
    #
    # @return [Object] the dependency value.
    #
    # @raise [Plumbum::Errors::MissingDependencyError] if no matching dependency
    #   is found.
    def get_plumbum_dependency(key)
      SleepingKingStudios::Tools::Toolbelt
        .instance
        .assertions.validate_name(key, as: :key)

      plumbum_providers.each do |provider|
        return provider.get(key) if provider.has?(key)
      end

      raise Plumbum::Errors::MissingDependencyError,
        "dependency not found with key #{key.inspect}"
    end
  end
end
