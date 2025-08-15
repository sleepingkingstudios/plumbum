# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'plumbum/rspec/deferred'

module Plumbum::RSpec::Deferred
  # Deferred examples for validating Plumbum::Consumer implementations.
  module ConsumerExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

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
