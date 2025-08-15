# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum'
require 'plumbum/consumers/class_methods'
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
      include Plumbum::Consumers::ClassMethods

      alias dependency plumbum_dependency

      alias dependency_keys plumbum_dependency_keys

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

      def each_plumbum_provider(&)
        return enum_for(:each_plumbum_provider) unless block_given?

        ancestors.reverse_each do |ancestor|
          next unless ancestor.respond_to?(:own_plumbum_providers, true)

          ancestor.own_plumbum_providers.each(&)
        end
      end
    end
  end
end
