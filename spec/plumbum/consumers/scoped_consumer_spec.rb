# frozen_string_literal: true

require 'plumbum/consumers/scoped_consumer'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumers::ScopedConsumer do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  subject(:consumer) { described_class.new(**options) }

  let(:described_class) { Spec::ExampleConsumer }
  let(:included_module) { Spec::IncludedConsumer }
  let(:parent_class)    { Spec::ParentConsumer }
  let(:options)         { {} }

  example_constant 'Spec::IncludedConsumer' do
    Module.new do
      include Plumbum::Consumers::ScopedConsumer
    end
  end

  example_class 'Spec::ParentConsumer' do |klass|
    klass.include Plumbum::Consumers::ScopedConsumer # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::ExampleConsumer', 'Spec::ParentConsumer' do |klass|
    klass.include Spec::IncludedConsumer
  end

  include_deferred 'with example providers'

  include_deferred 'should implement the Consumer class methods'

  include_deferred 'should implement the Consumer instance methods'

  include_deferred 'should generate the dependency methods'
end
