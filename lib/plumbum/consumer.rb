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
  #
  # @example Define a dependency with scoped key.
  #   class Client
  #     include Plumbum::Consumer
  #     include ConfigurationProvider
  #
  #     dependency 'config.network.default_server'
  #   end
  #
  #   client = Client.new
  #   client.default_server
  #   #=> returns the value of ConfigurationProvider.values[:config][:network][:default_server]
  #
  # @example Define multiple dependencies.
  #   class Rocket
  #     include Plumbum::Consumer
  #     include RocketPartsProvider
  #
  #     dependency :engine, :fusilage, :payload
  #   end
  #
  #   rocket = Rocket.new
  #   rocket.engine
  #   #=> returns the value of RocketPartsProvider.values[:engine]
  #
  # @example Define multiple dependencies with scoped keys.
  #   class Server
  #     include Plumbum::Consumer
  #     include ConfigurationProvider
  #
  #     dependency :port, :protocol, :timeout, scope: 'config.network'
  #   end
  #
  #   server = Server.new
  #   server.port
  #   #=> returns the value of ConfigurationProvider.values[:config][:network][:port]
  #
  # @example Define a method depndency.
  #   class Application
  #     include Plumbum::Consumer
  #     include ProcessManagerProvider
  #
  #     dependency '#restart', scope: :process_manager
  #   end
  #
  #   application = Application.new
  #   application.restart(force: true)
  #   #=> calls ProcessManagerProvider.values[:process_manager].restart(force: true)
  module Consumer
    include Plumbum::Consumers::InstanceMethods

    # Class methods to extend when including Plumbum::Consumer.
    module ClassMethods
      include Plumbum::Consumers::ClassMethods

      alias dependency plumbum_dependency

      alias dependency_keys plumbum_dependency_keys

      alias provider plumbum_provider

      # Callback invoked when Consumer is included in another module or class.
      #
      # This ensures that the Consumer methods propagate correctly across a
      # chain of included modules.
      def included(other)
        super

        other.extend(ClassMethods)
      end
    end

    class << self
      # Callback invoked when Consumer is included in another module or class.
      def included(other)
        super

        other.extend(ClassMethods)
      end
    end
  end
end
