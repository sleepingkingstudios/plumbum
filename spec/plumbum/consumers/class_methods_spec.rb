# frozen_string_literal: true

require 'plumbum/consumers/class_methods'
require 'plumbum/consumers/instance_methods'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumers::ClassMethods do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  let(:parent_class)    { Spec::ParentConsumer }
  let(:included_module) { Spec::IncludedConsumer }
  let(:described_class) { Spec::ExampleConsumer }

  example_constant 'Spec::IncludedConsumer' do
    Module.new do
      extend  Plumbum::Consumers::ClassMethods
      include Plumbum::Consumers::InstanceMethods
    end
  end

  example_class 'Spec::ParentConsumer' do |klass|
    klass.extend  Plumbum::Consumers::ClassMethods # rubocop:disable RSpec/DescribedClass
    klass.include Plumbum::Consumers::InstanceMethods
  end

  example_class 'Spec::ExampleConsumer', 'Spec::ParentConsumer' do |klass|
    klass.include Spec::IncludedConsumer
  end

  include_deferred 'should implement the Consumer class methods'
end
