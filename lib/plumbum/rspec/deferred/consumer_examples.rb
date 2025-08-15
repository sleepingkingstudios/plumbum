# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'plumbum/rspec/deferred'

module Plumbum::RSpec::Deferred
  # Deferred examples for validating Plumbum::Consumer implementations.
  module ConsumerExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    deferred_context 'when the class defines dependencies' do
      let(:class_dependencies) { %w[env tools] }

      before(:example) do
        described_class.plumbum_dependency('env')
        described_class.plumbum_dependency('tools')
      end
    end

    deferred_context 'when an included module defines dependencies' do
      let(:included_dependencies) { %w[context] }

      before(:example) do
        included_module.plumbum_dependency('context')
      end
    end

    deferred_context 'when the parent class defines dependencies' do
      let(:parent_dependencies) { %w[repository tools] }

      before(:example) do
        parent_class.plumbum_dependency('repository')
        parent_class.plumbum_dependency('tools')
      end
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
  end
end
