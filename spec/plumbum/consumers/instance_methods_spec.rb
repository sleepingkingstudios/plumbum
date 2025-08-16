# frozen_string_literal: true

require 'plumbum/consumers/instance_methods'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumers::InstanceMethods do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  subject(:consumer) { described_class.new }

  deferred_context 'when the class defines providers' do
    example_constant 'Spec::ConfigProvider' do
      Spec::ManyProvider.new(
        values: { env: 'test', repository: { books: [] }, tools: {} }
      )
    end

    example_constant 'Spec::ToolsProvider' do
      Spec::OneProvider.new(key: :tools, value: { string_tools: {} })
    end

    before(:example) do
      described_class.plumbum_providers = [
        Spec::ToolsProvider,
        Spec::ConfigProvider
      ]
    end
  end

  let(:described_class) { Spec::ExampleConsumer }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  example_class 'Spec::ExampleConsumer' do |klass|
    klass.include Plumbum::Consumers::InstanceMethods # rubocop:disable RSpec/DescribedClass

    klass.define_singleton_method(:plumbum_providers) do
      @plumbum_providers ||= []
    end

    klass.define_singleton_method(:plumbum_providers=) do |value|
      @plumbum_providers = value
    end
  end

  include_deferred 'with example providers'

  include_deferred 'should implement the Consumer instance methods'
end
