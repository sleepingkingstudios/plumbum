# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum'

module Plumbum
  # Provides methods for defining and accessing injected dependencies.
  #
  # @example Define a basic dependency.
  #   class Orchestrator
  #     include Plumbum::Consumer
  #     include ApplicationProvider
  #
  #     dependency :application
  #   end
  #
  #   Orchestrator.new.application
  #   #=> returns the value of ApplicationProvider.value
  #
  # @example Define an aliased dependency.
  #   class Orchestrator
  #     include Plumbum::Consumer
  #     include ApplicationProvider
  #
  #     dependency :application, as: :app
  #   end
  #
  #   Orchestrator.new.app
  #   #=> returns the value of ApplicationProvider.value
  #
  # @example Define an optional dependency.
  #   class BillCustomer
  #     include Plumbum::Consumer
  #
  #     dependency :rewards
  #   end
  #
  #   class BillRewardsCustomer < BillCustomer
  #     include RewardsProvider
  #   end
  #
  #   BillCustomer.new.rewards
  #   #=> returns nil
  #
  #   BillRewardsCustomer.new.rewards
  #   #=> returns RewardsProvider.value
  #
  # @example Define an unmemoized dependency.
  #   class Action
  #     include Plumbum::Consumer
  #     include RequestProvider
  #
  #     dependency :request, memoize: false
  #   end
  #
  #   action = Action.new
  #   action.request
  #   #=> returns the value of RequestProvider.value
  #
  #   request = Request.new
  #   RequestProvider.value = request
  #   action.request
  #   #=> returns the new request
  module Consumer
    extend SleepingKingStudios::Tools::Toolbox::Mixin

    # Class methods to extend when including Plumbum::Consumer.
    module ClassMethods
      # Defines an injected dependency for instances of the class.
      #
      # @param key [String, Symbol] the key for the dependency.
      # @param as [String, Symbol] the method name used to define dependency
      #   methods. Defaults to the key.
      # @param memoize [true, false] if true, memoizes the value of the
      #   dependency the first time it is successfully called. Defaults to true.
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
      def dependency(
        key,
        as:        nil,
        memoize:   true,
        optional:  false,
        predicate: false
      )
        validate_name(key, as: :key)
        validate_name(as,  as: :as) unless as.nil?

        key, method_name, path = split_key(key, as:)

        dependency_keys << key.to_s

        define_predicate(key:, method_name:) if predicate

        define_reader(key:, method_name:, memoize:, optional:, path:)
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

      # Registers a provider for the class.
      #
      # @provider [Plumbum::Provider] the provider to register.
      #
      # @return void
      def provider(provider) # rubocop:disable Metrics/MethodLength
        unless provider.is_a?(Plumbum::Provider)
          message =
            SleepingKingStudios::Tools::Toolbelt
            .instance
            .assertions
            .error_message_for(
              'sleeping_king_studios.tools.assertions.instance_of',
              as:       :provider,
              expected: Plumbum::Provider
            )

          raise ArgumentError, message
        end

        own_plumbum_providers.prepend(provider)

        nil
      end

      # @return [Array<Plumbum::Provider>] the providers defined for the class.
      def plumbum_providers
        each_plumbum_provider.to_a
      end

      protected

      def own_plumbum_providers
        @own_plumbum_providers ||= []
      end

      private

      def define_predicate(key:, method_name:)
        method_name = :"#{method_name}?"

        dependency_methods.define_method(method_name) do
          has_plumbum_dependency?(key)
        end
      end

      def define_reader(key:, memoize:, method_name:, optional:, path:)
        dependency_methods.define_method(method_name) do
          return get_scoped_dependency(key, optional:, path:) unless memoize

          if (@plumbum_dependencies ||= {}).key?(key)
            return @plumbum_dependencies[key]
          end

          get_scoped_dependency(key, optional:, path:).tap do |value|
            @plumbum_dependencies[key] = value unless value.nil?
          end
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

      def each_plumbum_provider(&)
        return enum_for(:each_plumbum_provider) unless block_given?

        ancestors.reverse_each do |ancestor|
          next unless ancestor.respond_to?(:own_plumbum_providers, true)

          ancestor.own_plumbum_providers.each(&)
        end
      end

      def split_key(key, as:)
        segments = key.to_s.split('.')

        return [key, as || key, nil] if segments.size == 1

        [segments.first, as || segments.last, segments[1..]]
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

    def get_scoped_dependency(key, path:, optional: false)
      dependency = get_plumbum_dependency(key, optional:)

      return dependency if path.nil? || path.empty?

      SleepingKingStudios::Tools::Toolbelt
        .instance
        .object_tools
        .dig(dependency, *path)
    end

    def handle_missing_plumbum_dependency(key, optional: false)
      return nil if optional

      raise Plumbum::Errors::MissingDependencyError,
        "dependency not found with key #{key.inspect}"
    end
  end
end
