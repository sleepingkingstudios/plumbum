# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'plumbum/rspec/deferred'

module Plumbum::RSpec::Deferred
  # Deferred examples for validating Plumbum::Consumer implementations.
  module ConsumerExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    define_method :tools do
      SleepingKingStudios::Tools::Toolbelt.instance
    end

    deferred_context 'with example providers' do
      example_class 'Spec::GenericProvider' do |klass|
        klass.include Plumbum::Provider
      end

      example_class 'Spec::ManyProvider', Module do |klass|
        klass.include Plumbum::Providers::Plural

        klass.define_method :initialize do |values:|
          tools = SleepingKingStudios::Tools::Toolbelt.instance

          @values = tools.hash_tools.convert_keys_to_strings(values)
        end
      end

      example_class 'Spec::MutableProvider', Module do |klass|
        klass.include Plumbum::Providers::Singular

        klass.define_method :initialize do |key:, value:|
          @key   = key.to_s
          @value = value
        end

        klass.attr_writer :value
      end

      example_class 'Spec::OneProvider', Module do |klass|
        klass.include Plumbum::Providers::Singular

        klass.define_method :initialize do |key:, value:|
          @key   = key.to_s
          @value = value
        end
      end
    end

    deferred_context 'when an included module defines dependencies' do
      let(:included_dependencies) { %w[context] }

      before(:example) do
        included_module.plumbum_dependency('context')
      end
    end

    deferred_context 'when an included module defines providers' do
      let(:expected_providers) do
        super() << Spec::ContextProvider
      end

      example_constant 'Spec::ContextProvider' do
        Spec::OneProvider.new(key: :context, value: Object.new.freeze)
      end

      before(:example) do
        included_module.plumbum_provider Spec::ContextProvider
      end
    end

    deferred_context 'when the class defines dependencies' do
      let(:class_dependencies) { %w[env tools] }

      before(:example) do
        described_class.plumbum_dependency('env')
        described_class.plumbum_dependency('tools')
      end
    end

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
        described_class.plumbum_provider Spec::ConfigProvider
        described_class.plumbum_provider Spec::ToolsProvider
      end
    end

    deferred_context 'when the parent class defines dependencies' do
      let(:parent_dependencies) { %w[repository tools] }

      before(:example) do
        parent_class.plumbum_dependency('repository')
        parent_class.plumbum_dependency('tools')
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
        parent_class.plumbum_provider Spec::OptionsProvider
      end
    end

    deferred_examples 'should implement the Consumer class methods' do
      describe '.plumbum_dependency' do
        deferred_examples 'should define the dependency' do
          let(:reader_name) { defined?(super()) ? super() : key.to_sym }

          it 'should return the reader name' do
            expect(described_class.plumbum_dependency(key))
              .to be reader_name.to_sym
          end

          it 'should add the key to the dependency keys' do
            expect { described_class.plumbum_dependency(key) }.to(
              change { dependency_keys }.to(include(expected_key))
            )
          end

          it 'should define the reader method', :aggregate_failures do
            expect(subject).not_to respond_to(reader_name)

            described_class.plumbum_dependency(key)

            expect(subject).to respond_to(reader_name).with(0).arguments
          end

          describe 'with as: nil' do
            it 'should return the reader name' do
              expect(described_class.plumbum_dependency(key))
                .to be reader_name.to_sym
            end

            it 'should add the key to the dependency keys' do
              expect { described_class.plumbum_dependency(key) }.to(
                change { dependency_keys }.to(include(expected_key))
              )
            end

            it 'should define the reader method', :aggregate_failures do
              expect(subject).not_to respond_to(reader_name)

              described_class.plumbum_dependency(key)

              expect(subject).to respond_to(reader_name).with(0).arguments
            end
          end

          describe 'with as: an Object' do
            let(:error_message) do
              tools
                .assertions
                .error_message_for(
                  'sleeping_king_studios.tools.assertions.name',
                  as: :as
                )
            end

            it 'should raise an exception' do
              expect do
                described_class.plumbum_dependency(key, as: Object.new.freeze)
              end
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with as: an empty String' do
            let(:error_message) do
              tools
                .assertions
                .error_message_for(
                  'sleeping_king_studios.tools.assertions.presence',
                  as: :as
                )
            end

            it 'should raise an exception' do
              expect { described_class.plumbum_dependency(key, as: '') }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with as: an empty Symbol' do
            let(:error_message) do
              tools
                .assertions
                .error_message_for(
                  'sleeping_king_studios.tools.assertions.presence',
                  as: :as
                )
            end

            it 'should raise an exception' do
              expect { described_class.plumbum_dependency(key, as: :'') }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with as: a String' do
            let(:scoped_name) { :"scoped_#{reader_name}" }
            let(:method_name) { scoped_name.to_s }

            it 'should return the reader name' do
              expect(described_class.plumbum_dependency(key, as: method_name))
                .to be scoped_name
            end

            it 'should add the key to the dependency keys' do
              expect do
                described_class.plumbum_dependency(key, as: method_name)
              end
                .to(change { dependency_keys }.to(include(expected_key)))
            end

            it 'should define the reader method', :aggregate_failures do
              expect(subject).not_to respond_to(reader_name)
              expect(subject).not_to respond_to(scoped_name)

              described_class.plumbum_dependency(key, as: method_name)

              expect(subject).not_to respond_to(reader_name)
              expect(subject).to respond_to(scoped_name).with(0).arguments
            end
          end

          describe 'with as: a Symbol' do
            let(:scoped_name) { :"scoped_#{reader_name}" }
            let(:method_name) { scoped_name }

            it 'should return the reader name' do
              expect(described_class.plumbum_dependency(key, as: method_name))
                .to be scoped_name
            end

            it 'should add the key to the dependency keys' do
              expect do
                described_class.plumbum_dependency(key, as: method_name)
              end
                .to change { dependency_keys }.to(include(expected_key))
            end

            it 'should define the reader method', :aggregate_failures do
              expect(subject).not_to respond_to(reader_name)
              expect(subject).not_to respond_to(scoped_name)

              described_class.plumbum_dependency(key, as: method_name)

              expect(subject).not_to respond_to(reader_name)
              expect(subject).to respond_to(scoped_name).with(0).arguments
            end
          end

          describe 'with predicate: true' do
            let(:predicate_name) { :"#{reader_name}?" }

            it 'should return the reader name' do
              expect(described_class.plumbum_dependency(key, predicate: true))
                .to be reader_name
            end

            it 'should add the key to the dependency keys' do
              expect do
                described_class.plumbum_dependency(key, predicate: true)
              end
                .to change { dependency_keys }.to(include(expected_key))
            end

            it 'should define the predicate method', :aggregate_failures do
              expect(subject).not_to respond_to(predicate_name)

              described_class.plumbum_dependency(key, predicate: true)

              expect(subject).to respond_to(predicate_name).with(0).arguments
            end

            it 'should define the reader method', :aggregate_failures do
              expect(subject).not_to respond_to(reader_name)

              described_class.plumbum_dependency(key, predicate: true)

              expect(subject).to respond_to(reader_name).with(0).arguments
            end

            describe 'with as: value' do
              let(:scoped_name)    { :"scoped_#{reader_name}" }
              let(:method_name)    { scoped_name.to_s }
              let(:predicate_name) { :"#{scoped_name}?" }

              it 'should define the predicate method', :aggregate_failures do
                expect(subject).not_to respond_to(predicate_name)

                described_class
                  .plumbum_dependency(key, as: method_name, predicate: true)

                expect(subject).to respond_to(predicate_name).with(0).arguments
              end

              it 'should define the reader method', :aggregate_failures do
                expect(subject).not_to respond_to(scoped_name)

                described_class
                  .plumbum_dependency(key, as: method_name, predicate: true)

                expect(subject).to respond_to(scoped_name).with(0).arguments
              end
            end
          end
        end

        define_method :dependency_keys do
          described_class.plumbum_dependency_keys(cache: false)
        end

        define_method :tools do
          SleepingKingStudios::Tools::Toolbelt.instance
        end

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:plumbum_dependency)
            .with(1).argument
            .and_keywords(:as, :memoize, :optional, :predicate)
        end

        describe 'with nil' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { described_class.plumbum_dependency(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.name',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { described_class.plumbum_dependency(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { described_class.plumbum_dependency('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty Symbol' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { described_class.plumbum_dependency(:'') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a valid String' do
          let(:key)          { 'valid' }
          let(:expected_key) { 'valid' }
          let(:reader_name)  { :valid }

          include_deferred 'should define the dependency'
        end

        describe 'with a valid Symbol' do
          let(:key)          { :valid }
          let(:expected_key) { 'valid' }
          let(:reader_name)  { :valid }

          include_deferred 'should define the dependency'
        end

        describe 'with a dot-separated String' do
          let(:key)          { 'application.tools.object_tools' }
          let(:expected_key) { 'application' }
          let(:reader_name)  { :object_tools }

          include_deferred 'should define the dependency'
        end

        describe 'with a dot-separated Symbol' do
          let(:key)          { :'application.tools.object_tools' }
          let(:expected_key) { 'application' }
          let(:reader_name)  { :object_tools }

          include_deferred 'should define the dependency'
        end
      end

      describe '.plumbum_dependency_keys' do
        it 'should define the method' do
          expect(described_class)
            .to respond_to(:plumbum_dependency_keys)
            .with(0).arguments
            .and_keywords(:cache)
        end

        it { expect(described_class.plumbum_dependency_keys).to be == Set.new }

        wrap_deferred 'when an included module defines dependencies' do
          let(:expected_dependencies) { included_dependencies }

          it 'should return the class dependencies' do
            expect(described_class.plumbum_dependency_keys)
              .to be_a(Set)
              .and match_array(expected_dependencies)
          end
        end

        wrap_deferred 'when the parent class defines dependencies' do
          let(:expected_dependencies) { parent_dependencies }

          it 'should return the class dependencies' do
            expect(described_class.plumbum_dependency_keys)
              .to be_a(Set)
              .and match_array(expected_dependencies)
          end
        end

        wrap_deferred 'when the class defines dependencies' do
          let(:expected_dependencies) { class_dependencies }

          it 'should return the class dependencies' do
            expect(described_class.plumbum_dependency_keys)
              .to be_a(Set)
              .and match_array(expected_dependencies)
          end
        end

        context 'when the class and ancestors define dependencies' do
          let(:expected_dependencies) do
            [
              *parent_dependencies,
              *class_dependencies,
              *included_dependencies
            ].uniq
          end

          include_deferred 'when the parent class defines dependencies'
          include_deferred 'when an included module defines dependencies'
          include_deferred 'when the class defines dependencies'

          it 'should return the parent class and class dependencies' do
            expect(described_class.plumbum_dependency_keys)
              .to be_a(Set)
              .and match_array(expected_dependencies)
          end
        end

        context 'when the dependency keys change' do
          before(:example) do
            # Memoize value.
            described_class.plumbum_dependency_keys

            described_class.plumbum_dependency 'added_dependency'
          end

          it 'should not update the dependency keys' do
            expect(described_class.plumbum_dependency_keys).to be == Set.new
          end

          describe 'with cache: false' do
            it 'should update the dependency keys' do
              expect(described_class.plumbum_dependency_keys(cache: false))
                .to be == Set.new(%w[added_dependency])
            end
          end

          describe 'with cache: true' do
            it 'should not update the dependency keys' do
              expect(described_class.plumbum_dependency_keys(cache: true))
                .to be == Set.new
            end
          end
        end
      end

      describe '.plumbum_provider' do
        it 'should define the method' do
          expect(described_class)
            .to respond_to(:plumbum_provider)
            .with(1).argument
        end

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
            expect { described_class.plumbum_provider(nil) }
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
            expect { described_class.plumbum_provider(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a provider' do
          let(:provider) { Spec::GenericProvider.new }

          define_method :defined_providers do
            described_class.plumbum_providers(cache: false)
          end

          it { expect(described_class.plumbum_provider(provider)).to be nil }

          it 'should add the provider to #plumbum_providers',
            :aggregate_failures \
          do
            expect { described_class.plumbum_provider(provider) }.to(
              change { defined_providers.count }.by(1)
            )

            expect(defined_providers.first).to be provider
          end

          wrap_deferred 'when the class defines providers' do
            it 'should add the provider to #plumbum_providers',
              :aggregate_failures \
            do
              expect { described_class.plumbum_provider(provider) }.to(
                change { defined_providers.count }.by(1)
              )

              expect(defined_providers.first).to be provider
            end
          end
        end
      end

      describe '.plumbum_providers' do
        let(:expected_providers) { [] }

        it 'should define the method' do
          expect(described_class)
            .to respond_to(:plumbum_providers)
            .with(0).arguments
            .and_keywords(:cache)
        end

        it { expect(described_class.plumbum_providers).to be == [] }

        wrap_deferred 'when the parent class defines providers' do
          it 'should return the expected providers' do
            expect(described_class.plumbum_providers).to eq(expected_providers)
          end
        end

        wrap_deferred 'when the class defines providers' do
          it 'should return the expected providers' do
            expect(described_class.plumbum_providers).to eq(expected_providers)
          end
        end

        wrap_deferred 'when an included module defines dependencies' do
          it 'should return the expected providers' do
            expect(described_class.plumbum_providers).to eq(expected_providers)
          end
        end

        context 'when the class and ancestors define providers' do
          include_deferred 'when the parent class defines providers'
          include_deferred 'when an included module defines providers'
          include_deferred 'when the class defines providers'

          it 'should return the expected providers' do
            expect(described_class.plumbum_providers).to eq(expected_providers)
          end
        end

        context 'when the providers change' do
          let(:generic_provider) { Spec::GenericProvider.new }

          before(:example) do
            # Memoize value.
            described_class.plumbum_providers

            described_class.plumbum_provider generic_provider
          end

          it 'should not update the dependency keys' do
            expect(described_class.plumbum_providers).to be == []
          end

          describe 'with cache: false' do
            it 'should update the dependency keys' do
              expect(described_class.plumbum_providers(cache: false))
                .to be == [generic_provider]
            end
          end

          describe 'with cache: true' do
            it 'should not update the dependency keys' do
              expect(described_class.plumbum_providers(cache: true))
                .to be == []
            end
          end
        end
      end
    end

    deferred_examples 'should implement the Consumer instance methods' do
      describe '#get_plumbum_dependency' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:get_plumbum_dependency)
            .with(1).argument
            .and_keywords(:optional)
        end

        describe 'with nil' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.get_plumbum_dependency(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.name',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.get_plumbum_dependency(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.get_plumbum_dependency('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty Symbol' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.get_plumbum_dependency(:'') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a non-matching String' do
          let(:error_message) do
            'dependency not found with key "invalid"'
          end

          it 'should raise an exception' do
            expect { subject.get_plumbum_dependency('invalid') }.to raise_error(
              Plumbum::Errors::MissingDependencyError,
              error_message
            )
          end
        end

        describe 'with a non-matching Symbol' do
          let(:error_message) do
            'dependency not found with key :invalid'
          end

          it 'should raise an exception' do
            expect { subject.get_plumbum_dependency(:invalid) }.to raise_error(
              Plumbum::Errors::MissingDependencyError,
              error_message
            )
          end
        end

        wrap_deferred 'when the class defines providers' do
          describe 'with a non-matching String' do
            let(:error_message) do
              'dependency not found with key "invalid"'
            end

            it 'should raise an exception' do
              expect { subject.get_plumbum_dependency('invalid') }
                .to raise_error(
                  Plumbum::Errors::MissingDependencyError,
                  error_message
                )
            end
          end

          describe 'with a non-matching Symbol' do
            let(:error_message) do
              'dependency not found with key :invalid'
            end

            it 'should raise an exception' do
              expect { subject.get_plumbum_dependency(:invalid) }
                .to raise_error(
                  Plumbum::Errors::MissingDependencyError,
                  error_message
                )
            end
          end

          describe 'with a matching String' do
            it 'should return the dependency value' do
              expect(subject.get_plumbum_dependency('env'))
                .to eq(Spec::ConfigProvider.values['env'])
            end

            context 'with a String matching multiple providers' do
              it 'should return the value from the last provider' do
                expect(subject.get_plumbum_dependency('tools'))
                  .to eq(Spec::ToolsProvider.value)
              end
            end
          end

          describe 'with a matching Symbol' do
            it 'should return the dependency value' do
              expect(subject.get_plumbum_dependency(:env))
                .to eq(Spec::ConfigProvider.values['env'])
            end

            context 'with a Symbol matching multiple providers' do
              it 'should return the value from the last provider' do
                expect(subject.get_plumbum_dependency(:tools))
                  .to eq(Spec::ToolsProvider.value)
              end
            end
          end
        end
      end

      describe '#has_plumbum_dependency?' do
        it 'should define the method' do
          expect(subject)
            .to respond_to(:has_plumbum_dependency?)
            .with(1).argument
        end

        describe 'with nil' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.has_plumbum_dependency?(nil) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.name',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.has_plumbum_dependency?(Object.new.freeze) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty String' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.has_plumbum_dependency?('') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an empty Symbol' do
          let(:error_message) do
            tools
              .assertions
              .error_message_for(
                'sleeping_king_studios.tools.assertions.presence',
                as: :key
              )
          end

          it 'should raise an exception' do
            expect { subject.has_plumbum_dependency?(:'') }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a non-matching String' do
          it { expect(subject.has_plumbum_dependency?('invalid')).to be false }
        end

        describe 'with a non-matching Symbol' do
          it { expect(subject.has_plumbum_dependency?(:invalid)).to be false }
        end

        wrap_deferred 'when the class defines providers' do
          describe 'with a non-matching String' do
            let(:value) { 'invalid' }

            it { expect(subject.has_plumbum_dependency?(value)).to be false }
          end

          describe 'with a non-matching Symbol' do
            it { expect(subject.has_plumbum_dependency?(:invalid)).to be false }
          end

          describe 'with a matching String' do
            it { expect(subject.has_plumbum_dependency?('tools')).to be true }
          end

          describe 'with a matching Symbol' do
            it { expect(subject.has_plumbum_dependency?(:tools)).to be true }
          end
        end
      end
    end

    deferred_examples 'should generate the dependency methods' do
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
                expect(consumer.tools)
                  .to eq({ tools: Spec::ToolsProvider.value })
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

            it 'should return the dependency value' do
              expect(consumer.integration).to be Spec::RailtieProvider.value
            end
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
            described_class
              .dependency('application.tools.object_tools', as: :obj)
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

        context 'when the class defines an optional drilled dependency' do
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

          it 'should define the predicate' do
            expect(consumer).to respond_to(:flag_enabled?).with(0).arguments
          end

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

              context 'when the class overwrites the method' do
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

        context 'when the class defines a drilled dependency with a predicate' \
        do
          before(:example) do
            described_class
              .dependency('application.tools.object_tools', predicate: true)
          end

          it 'should define the predicate' do
            expect(consumer).to respond_to(:object_tools?).with(0).arguments
          end

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
  end
end
