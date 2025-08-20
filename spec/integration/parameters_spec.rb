# frozen_string_literal: true

require 'plumbum'

RSpec.describe Plumbum::Parameters do
  subject(:consumer) { described_class.new(**keywords) }

  example_class 'Spec::Consumer' do |klass|
    klass.include Plumbum::Consumer
    klass.prepend Plumbum::Parameters # rubocop:disable RSpec/DescribedClass

    klass.dependency :injected

    klass.define_method(:initialize) do |parameter:|
      super()

      @parameter = parameter

      validate_presence(injected)
      validate_presence(parameter)
    end

    klass.attr_reader :parameter

    klass.define_method(:validate_presence) do |value|
      raise "value can't be blank" if value.nil?
    end
  end

  let(:described_class) { Spec::Consumer }
  let(:keywords) do
    {
      injected:  'injected value',
      parameter: 'parameter value'
    }
  end

  describe '.new' do
    describe 'with injected: nil' do
      let(:keywords) { super().merge(injected: nil) }

      it 'should raise an exception' do
        expect { described_class.new(**keywords) }
          .to raise_error "value can't be blank"
      end
    end

    describe 'with parameter: nil' do
      let(:keywords) { super().merge(parameter: nil) }

      it 'should raise an exception' do
        expect { described_class.new(**keywords) }
          .to raise_error "value can't be blank"
      end
    end
  end

  describe '#injected' do
    it { expect(consumer.injected).to be == 'injected value' }
  end

  describe '#parameter' do
    it { expect(consumer.parameter).to be == 'parameter value' }
  end
end
