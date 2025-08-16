# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum/consumers'
require 'plumbum/consumers/class_methods'
require 'plumbum/consumers/instance_methods'

module Plumbum::Consumers
  # Consumer implementation with fully-scoped method names for compatibility.
  #
  # Use a scoped consumer when the standard Consumer DSL class methods (such as
  # .dependency and .provider) might conflict with existing methods.
  #
  # @see Plumbum::Consumer
  module ScopedConsumer
    extend  SleepingKingStudios::Tools::Toolbox::Mixin
    include Plumbum::Consumers::InstanceMethods

    # Class methods to extend when including Plumbum::Consumer.
    module ClassMethods
      include Plumbum::Consumers::ClassMethods
    end
  end
end
