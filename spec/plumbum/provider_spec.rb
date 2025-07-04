# frozen_string_literal: true

require 'plumbum/provider'
require 'plumbum/rspec/deferred/provider_examples'

RSpec.describe Plumbum::Provider do
  include Plumbum::RSpec::Deferred::ProviderExamples

  subject(:provider) { Object.new.extend(described_class) }

  let(:valid_pairs) { {} }

  include_deferred 'should implement the Provider interface'

  context 'with a concrete Provider implementation' do
    subject(:provider) { Spec::Provider.new }

    let(:valid_pairs) { { 'option' => 'value' } }

    example_class 'Spec::Provider' do |klass|
      klass.include Plumbum::Provider # rubocop:disable RSpec/DescribedClass

      klass.define_method :get_value do |key|
        key == 'option' ? 'value' : nil
      end

      klass.define_method :has_value? do |key|
        key == 'option'
      end
    end

    include_deferred 'should implement the Provider interface'
  end
end
