# frozen_string_literal: true

require 'plumbum/providers/plural'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Providers::Plural do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { described_class.new(values) }

  let(:described_class) { Spec::Provider }
  let(:values)          { { 'option' => 'value', 'number' => 123 } }
  let(:valid_pairs)     { values }

  example_class 'Spec::Provider' do |klass|
    klass.include Plumbum::Providers::Plural # rubocop:disable RSpec/DescribedClass

    klass.define_method :initialize do |values|
      @values = values
    end
  end

  include_deferred 'should implement the Provider interface'

  describe '#values' do
    include_examples 'should define reader', :values, -> { values }
  end
end
