# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Functionality for defining consumers.
  module Consumers
    autoload :ClassMethods,    'plumbum/consumers/class_methods'
    autoload :InstanceMethods, 'plumbum/consumers/instance_methods'
    autoload :ScopedConsumer,  'plumbum/consumers/scoped_consumer'
  end
end
