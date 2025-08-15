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

      alias provider plumbum_provider
    end
  end
end
