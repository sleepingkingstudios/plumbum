# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum'
require 'plumbum/consumers/instance_methods'

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
    extend  SleepingKingStudios::Tools::Toolbox::Mixin
    include Plumbum::Consumers::InstanceMethods

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

        if memoize
          define_memoized_reader(key:, method_name:, optional:, path:)
        else
          define_reader(key:, method_name:, optional:, path:)
        end
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

      def define_memoized_reader(key:, method_name:, optional:, path:)
        dependency_methods.define_method(method_name) do
          if (@plumbum_dependencies ||= {}).key?(key)
            return @plumbum_dependencies[key]
          end

          get_scoped_plumbum_dependency(key, optional:, path:).tap do |value|
            @plumbum_dependencies[key] = value unless value.nil?
          end
        end
      end

      def define_predicate(key:, method_name:)
        method_name = :"#{method_name}?"

        dependency_methods.define_method(method_name) do
          has_plumbum_dependency?(key)
        end
      end

      def define_reader(key:, method_name:, optional:, path:)
        dependency_methods.define_method(method_name) do
          get_scoped_plumbum_dependency(key, optional:, path:)
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
  end
end
