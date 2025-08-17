# frozen_string_literal: true

require 'plumbum/consumers/instance_methods'
require 'plumbum/many_provider'
require 'plumbum/one_provider'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumers::InstanceMethods do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  subject(:consumer) { described_class.new }

  deferred_context 'when the class defines providers' do
    let(:config_provider) do
      Plumbum::ManyProvider.new(
        values: { env: 'test', repository: { books: [] }, tools: {} }
      )
    end
    let(:tools_provider) do
      Plumbum::OneProvider.new(:tools, value: { string_tools: {} })
    end

    before(:example) do
      described_class.plumbum_providers = [
        tools_provider,
        config_provider
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
