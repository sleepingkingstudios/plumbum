# frozen_string_literal: true

require 'plumbum/consumers/class_methods'
require 'plumbum/consumers/instance_methods'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumers::ClassMethods do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  let(:parent_class)    { Spec::ParentConsumer }
  let(:described_class) { Spec::ExampleConsumer }

  example_class 'Spec::ParentConsumer' do |klass|
    klass.extend  Plumbum::Consumers::ClassMethods # rubocop:disable RSpec/DescribedClass
    klass.include Plumbum::Consumers::InstanceMethods
  end

  example_class 'Spec::ExampleConsumer', 'Spec::ParentConsumer'

  include_deferred 'should implement the Consumer class methods'
end
