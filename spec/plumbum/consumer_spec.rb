# frozen_string_literal: true

require 'plumbum/consumer'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumer do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  subject(:consumer) { described_class.new(**options) }

  let(:described_class) { Spec::ExampleConsumer }
  let(:included_module) { Spec::IncludedConsumer }
  let(:parent_class)    { Spec::ParentConsumer }
  let(:options)         { {} }

  example_constant 'Spec::IncludedConsumer' do
    Module.new do
      include Plumbum::Consumer
    end
  end

  example_class 'Spec::ParentConsumer' do |klass|
    klass.include Plumbum::Consumer # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::ExampleConsumer', 'Spec::ParentConsumer' do |klass|
    klass.include Spec::IncludedConsumer
  end

  include_deferred 'with example providers'

  include_deferred 'should implement the Consumer class methods'

  include_deferred 'should implement the Consumer instance methods'

  include_deferred 'should generate the dependency methods'

  describe '.dependency' do
    it 'should alias the method' do
      original_method = described_class.method(:plumbum_dependency)
      aliased_method  = described_class.method(:dependency)

      expect(original_method.source_location)
        .to be == aliased_method.source_location
    end
  end

  describe '.dependency_keys' do
    it 'should alias the method' do
      original_method = described_class.method(:plumbum_dependency_keys)
      aliased_method  = described_class.method(:dependency_keys)

      expect(original_method.source_location)
        .to be == aliased_method.source_location
    end
  end

  describe '.provider' do
    it 'should alias the method' do
      original_method = described_class.method(:plumbum_provider)
      aliased_method  = described_class.method(:provider)

      expect(original_method.source_location)
        .to be == aliased_method.source_location
    end
  end
end
