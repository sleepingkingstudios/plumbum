# frozen_string_literal: true

require 'plumbum/consumer'
require 'plumbum/rspec/deferred/consumer_examples'

RSpec.describe Plumbum::Consumer do
  include Plumbum::RSpec::Deferred::ConsumerExamples

  subject(:consumer) { described_class.new(**options) }

  deferred_context 'when the class defines providers' do
    let(:expected_providers) do
      super() << Spec::ToolsProvider << Spec::ConfigProvider
    end

    example_constant 'Spec::ConfigProvider' do
      Spec::ManyProvider.new(
        values: { env: 'test', repository: { books: [] }, tools: {} }
      )
    end

    example_constant 'Spec::ToolsProvider' do
      Spec::OneProvider.new(key: :tools, value: { string_tools: {} })
    end

    before(:example) do
      described_class.provider Spec::ConfigProvider
      described_class.provider Spec::ToolsProvider
    end
  end

  deferred_context 'when the parent class defines providers' do
    let(:expected_providers) do
      super() << Spec::OptionsProvider
    end

    example_constant 'Spec::OptionsProvider' do
      Spec::OneProvider.new(key: :options, value: { key: 'value' })
    end

    before(:example) do
      parent_class.provider Spec::OptionsProvider
    end
  end

  let(:described_class) { Spec::ExampleConsumer }
  let(:included_module) { Spec::IncludedConsumer }
  let(:parent_class)    { Spec::ParentConsumer }
  let(:options)         { {} }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

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
    it { expect(described_class).to respond_to(:provider).with(1).argument }

    describe 'with nil' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.instance_of',
            as:       :provider,
            expected: Plumbum::Provider
          )
      end

      it 'should raise an exception' do
        expect { described_class.provider(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an Object' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.instance_of',
            as:       :provider,
            expected: Plumbum::Provider
          )
      end

      it 'should raise an exception' do
        expect { described_class.provider(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a Module' do
      let(:error_message) do
        tools
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.instance_of',
            as:       :provider,
            expected: Plumbum::Provider
          )
      end

      it 'should raise an exception' do
        expect { described_class.provider(Module.new) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a provider' do
      let(:provider) { Spec::GenericProvider.new }

      it { expect(described_class.provider(provider)).to be nil }

      it 'should add the provider to #plumbum_providers', :aggregate_failures do
        expect { described_class.provider(provider) }.to(
          change { described_class.plumbum_providers.count }.by(1)
        )

        expect(described_class.plumbum_providers.first).to be provider
      end

      wrap_deferred 'when the class defines providers' do
        it 'should add the provider to #plumbum_providers',
          :aggregate_failures \
        do
          expect { described_class.provider(provider) }.to(
            change { described_class.plumbum_providers.count }.by(1)
          )

          expect(described_class.plumbum_providers.first).to be provider
        end
      end
    end
  end

  describe '.plumbum_providers' do
    let(:expected_providers) { [] }

    it 'should define the class reader' do
      expect(described_class)
        .to define_reader(:plumbum_providers)
        .with_value([])
    end

    wrap_deferred 'when the class defines providers' do # rubocop:disable RSpec/RepeatedExampleGroupBody
      it { expect(described_class.plumbum_providers).to eq(expected_providers) }
    end

    wrap_deferred 'when the parent class defines providers' do # rubocop:disable RSpec/RepeatedExampleGroupBody
      it { expect(described_class.plumbum_providers).to eq(expected_providers) }
    end

    context 'when the class and parent class define providers' do
      include_deferred 'when the parent class defines providers'
      include_deferred 'when the class defines providers'

      it { expect(described_class.plumbum_providers).to eq(expected_providers) }
    end
  end

  describe '#:dependency' do
    it { expect(consumer).not_to respond_to(:tools) }

    wrap_deferred 'when the class defines dependencies' do
      let(:error_message) do
        'dependency not found with key "tools"'
      end

      it { expect(consumer).to respond_to(:tools).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.tools }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      wrap_deferred 'when the class defines providers' do
        it { expect(consumer.tools).to be Spec::ToolsProvider.value }

        context 'when the class overwrites the method' do
          before(:example) do
            described_class.define_method(:tools) do
              { tools: super() }
            end
          end

          it 'should use the class definition' do
            expect(consumer.tools).to eq({ tools: Spec::ToolsProvider.value })
          end
        end
      end
    end

    context 'when the class defines a dependency with as: value' do
      let(:error_message) do
        'dependency not found with key "railtie"'
      end

      before(:example) do
        described_class.dependency('railtie', as: 'integration')
      end

      it { expect(consumer).to respond_to(:integration).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.integration }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        example_constant 'Spec::RailtieProvider' do
          Spec::OneProvider.new(key: :railtie, value: Object.new.freeze)
        end

        before(:example) do
          described_class.provider Spec::RailtieProvider
        end

        it { expect(consumer.integration).to be Spec::RailtieProvider.value }
      end
    end

    context 'when the class defines a dependency with memoize: false' do
      let(:error_message) do
        'dependency not found with key "request"'
      end

      before(:example) do
        described_class.dependency('request', memoize: false)
      end

      it { expect(consumer).to respond_to(:request).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.request }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        let(:original_value) { { http_method: :get } }

        example_constant 'Spec::RequestProvider' do
          Spec::MutableProvider.new(key: :request, value: original_value)
        end

        before(:example) do
          described_class.dependency('request', memoize: false)

          described_class.provider Spec::RequestProvider
        end

        it { expect(consumer.request).to be Spec::RequestProvider.value }

        context 'when the provider value changes' do
          let(:changed_value) { { http_method: :post } }

          before(:example) do
            consumer.request # Cache the dependency.

            Spec::RequestProvider.value = changed_value
          end

          it { expect(consumer.request).to be Spec::RequestProvider.value }
        end
      end
    end

    context 'when the class defines a dependency with memoize: true' do
      let(:error_message) do
        'dependency not found with key "request"'
      end

      before(:example) do
        described_class.dependency('request', memoize: true)
      end

      it { expect(consumer).to respond_to(:request).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.request }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        let(:original_value) { { http_method: :get } }

        example_constant 'Spec::RequestProvider' do
          Spec::MutableProvider.new(key: :request, value: original_value)
        end

        before(:example) do
          described_class.dependency('request', memoize: true)

          described_class.provider Spec::RequestProvider
        end

        it { expect(consumer.request).to be Spec::RequestProvider.value }

        context 'when the provider value changes' do
          let(:changed_value) { { http_method: :post } }

          before(:example) do
            consumer.request # Cache the dependency.

            Spec::RequestProvider.value = changed_value
          end

          it { expect(consumer.request).to be original_value }
        end
      end
    end

    context 'when the class defines a dependency with optional: false' do
      let(:error_message) do
        'dependency not found with key "railtie"'
      end

      before(:example) do
        described_class.dependency('railtie', optional: false)
      end

      it { expect(consumer).to respond_to(:railtie).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.railtie }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        example_constant 'Spec::RailtieProvider' do
          Spec::OneProvider.new(key: :railtie, value: Object.new.freeze)
        end

        before(:example) do
          described_class.provider Spec::RailtieProvider
        end

        it { expect(consumer.railtie).to be Spec::RailtieProvider.value }
      end
    end

    context 'when the class defines a dependency with optional: true' do
      before(:example) do
        described_class.dependency('railtie', optional: true)
      end

      it { expect(consumer).to respond_to(:railtie).with(0).arguments }

      it { expect(consumer.railtie).to be nil }

      context 'when the class includes a provider for the dependency' do
        example_constant 'Spec::RailtieProvider' do
          Spec::OneProvider.new(key: :railtie, value: Object.new.freeze)
        end

        before(:example) do
          described_class.provider Spec::RailtieProvider
        end

        it { expect(consumer.railtie).to be Spec::RailtieProvider.value }
      end
    end

    context 'when the class defines a drilled dependency' do
      let(:error_message) do
        'dependency not found with key "application"'
      end

      before(:example) do
        described_class.dependency('application.tools.object_tools')
      end

      it { expect(consumer).to respond_to(:object_tools).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.object_tools }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        let(:object_tools) { Object.new.freeze }
        let(:tools)        { Struct.new(:object_tools).new(object_tools) }
        let(:application)  { Struct.new(:tools).new(tools) }

        example_constant 'Spec::ApplicationProvider' do
          Spec::OneProvider.new(key: :application, value: application)
        end

        before(:example) do
          described_class.provider Spec::ApplicationProvider
        end

        it { expect(consumer.object_tools).to be object_tools }
      end
    end

    context 'when the class defines a drilled dependency with as: value' do
      let(:error_message) do
        'dependency not found with key "application"'
      end

      before(:example) do
        described_class.dependency('application.tools.object_tools', as: :obj)
      end

      it { expect(consumer).to respond_to(:obj).with(0).arguments }

      it 'should raise an exception' do
        expect { consumer.obj }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        let(:object_tools) { Object.new.freeze }
        let(:tools)        { Struct.new(:object_tools).new(object_tools) }
        let(:application)  { Struct.new(:tools).new(tools) }

        example_constant 'Spec::ApplicationProvider' do
          Spec::OneProvider.new(key: :application, value: application)
        end

        before(:example) do
          described_class.provider Spec::ApplicationProvider
        end

        it { expect(consumer.obj).to be object_tools }
      end
    end

    context 'when the class defines a drilled dependency with optional: true' do
      before(:example) do
        described_class
          .dependency('application.tools.object_tools', optional: true)
      end

      it { expect(consumer).to respond_to(:object_tools).with(0).arguments }

      it { expect(consumer.object_tools).to be nil }

      context 'when the class includes a provider for the dependency' do
        let(:object_tools) { Object.new.freeze }
        let(:tools)        { Struct.new(:object_tools).new(object_tools) }
        let(:application)  { Struct.new(:tools).new(tools) }

        example_constant 'Spec::ApplicationProvider' do
          Spec::OneProvider.new(key: :application, value: application)
        end

        before(:example) do
          described_class.provider Spec::ApplicationProvider
        end

        it { expect(consumer.object_tools).to be object_tools }
      end
    end

    context 'when the class includes a mutable provider' do
      let(:original_value) { { http_method: :get } }

      example_constant 'Spec::RequestProvider' do
        Spec::MutableProvider.new(key: :request, value: original_value)
      end

      before(:example) do
        described_class.dependency('request')

        described_class.provider Spec::RequestProvider
      end

      it { expect(consumer.request).to be Spec::RequestProvider.value }

      context 'when the provider value changes' do
        let(:changed_value) { { http_method: :post } }

        before(:example) do
          consumer.request # Cache the dependency.

          Spec::RequestProvider.value = changed_value
        end

        it { expect(consumer.request).to be original_value }
      end
    end
  end

  describe '#:dependency?' do
    wrap_deferred 'when the class defines dependencies' do
      it { expect(consumer).not_to respond_to(:tools?) }
    end

    context 'when the class defines a dependency with predicate: false' do
      before(:example) do
        described_class.dependency('flag_enabled', predicate: false)
      end

      it { expect(consumer).not_to respond_to(:flag_enabled?) }
    end

    context 'when the class defines a dependency with predicate: true' do
      before(:example) do
        described_class.dependency('flag_enabled', predicate: true)
      end

      it { expect(consumer).to respond_to(:flag_enabled?).with(0).arguments }

      it { expect(consumer.flag_enabled?).to be false }

      context 'with as: value' do
        before(:example) do
          described_class
            .dependency('flag_enabled', as: 'flag', predicate: true)
        end

        it { expect(consumer).to respond_to(:flag?).with(0).arguments }

        it { expect(consumer.flag?).to be false }

        context 'when the class defines providers' do
          example_constant 'Spec::FlagProvider' do
            Spec::OneProvider.new(key: :flag_enabled, value: false)
          end

          before(:example) do
            described_class.provider Spec::FlagProvider
          end

          it { expect(consumer.flag?).to be true }

          context 'when the class overwrites the method' do # rubocop:disable RSpec/NestedGroups
            before(:example) do
              described_class.define_method(:flag?) do
                super().to_s
              end
            end

            it 'should use the class definition' do
              expect(consumer.flag?).to eq 'true'
            end
          end
        end
      end

      context 'when the class overwrites the method' do
        before(:example) do
          described_class.define_method(:flag_enabled?) do
            super().to_s
          end
        end

        it 'should use the class definition' do
          expect(consumer.flag_enabled?).to eq 'false'
        end
      end

      context 'when the class defines providers' do
        example_constant 'Spec::FlagProvider' do
          Spec::OneProvider.new(key: :flag_enabled, value: false)
        end

        before(:example) do
          described_class.provider Spec::FlagProvider
        end

        it { expect(consumer.flag_enabled?).to be true }

        context 'when the class overwrites the method' do
          before(:example) do
            described_class.define_method(:flag_enabled?) do
              super().to_s
            end
          end

          it 'should use the class definition' do
            expect(consumer.flag_enabled?).to eq 'true'
          end
        end
      end
    end

    context 'when the class defines a drilled dependency with a predicate' do
      before(:example) do
        described_class
          .dependency('application.tools.object_tools', predicate: true)
      end

      it { expect(consumer).to respond_to(:object_tools?).with(0).arguments }

      it { expect(consumer.object_tools?).to be false }

      context 'when the class includes a provider for the dependency' do
        example_constant 'Spec::ApplicationProvider' do
          Spec::OneProvider.new(key: :application, value: Object.new.freeze)
        end

        before(:example) do
          described_class.provider Spec::ApplicationProvider
        end

        it { expect(consumer.object_tools?).to be true }
      end
    end
  end
end
