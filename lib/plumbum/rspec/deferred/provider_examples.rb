# frozen_string_literal: true

require 'rspec/sleeping_king_studios/deferred/provider'

require 'plumbum/rspec/deferred'

module Plumbum::RSpec::Deferred
  # Deferred examples for validating Plumbum::Provider implementations.
  module ProviderExamples
    include RSpec::SleepingKingStudios::Deferred::Provider

    # Asserts that the method handles invalid keys.
    #
    # The following methods must be defined in the example group:
    #
    # - #call_method: a helper method that takes one :key argument and calls the
    #   tested method.
    deferred_examples 'should validate the key' do
      include RSpec::SleepingKingStudios::Deferred::Dependencies

      depends_on :call_method,
        'a helper method that takes one :key argument and calls the method ' \
        'under test'

      define_method :tools do
        SleepingKingStudios::Tools::Toolbelt.instance
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
          expect { call_method(nil) }
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
          expect { call_method(Object.new.freeze) }
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
          expect { call_method('') }
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
          expect { call_method(:'') }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    # Asserts that the provider handles incompatible options.
    #
    # The following methods must be defined in the example group:
    #
    # - #call_method: a helper method that takes one :options argument and calls
    #   the tested method.
    deferred_examples 'should validate the options' do
      include RSpec::SleepingKingStudios::Deferred::Dependencies

      depends_on :call_method,
        'a helper method that takes one :options argument and calls the ' \
        'method under test'

      describe 'with read_only: value and write_once: value' do
        let(:options) do
          super().merge(read_only: false, write_once: true)
        end
        let(:error_message) do
          'incompatible options :read_only and :write_once'
        end

        it 'should raise an exception' do
          expect { call_method(options) }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    # Asserts that the object implements the Plumbum::Provider interface.
    #
    # The following methods must be defined in the example group:
    #
    # - #valid_pairs: A Hash containing the valid keys the provider should
    #   return and the corresponding values.
    #
    # The behavior can be customized by defining the following methods:
    #
    # - #invalid_key: An example key that does not match the provider. The
    #   default value is :invalid.
    deferred_examples 'should implement the Provider interface' \
    do |has_options: true|
      include RSpec::SleepingKingStudios::Deferred::Dependencies

      depends_on :valid_pairs,
        'a Hash containing the valid keys the provider should return and ' \
        'the corresponding values.'

      describe '#get' do
        let(:invalid_key) { defined?(super()) ? super() : :invalid }

        define_method :call_method do |key|
          subject.get(key)
        end

        it { expect(subject).to respond_to(:get).with(1).argument }

        include_deferred 'should validate the key'

        describe 'with an invalid String' do
          it { expect(subject.get(invalid_key.to_s)).to be nil }
        end

        describe 'with an invalid Symbol' do
          it { expect(subject.get(invalid_key.to_sym)).to be nil }
        end

        describe 'with a valid String', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each do |key, value|
              expect(subject.get(key.to_s)).to be value
            end
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          it 'should return the value' do
            valid_pairs.each do |key, value|
              expect(subject.get(key.to_sym)).to be value
            end
          end
        end
      end

      describe '#has?' do
        let(:invalid_key) { defined?(super()) ? super() : :invalid }

        define_method :call_method do |key|
          subject.has?(key)
        end

        it { expect(subject).to respond_to(:has?).with(1).argument }

        include_deferred 'should validate the key'

        describe 'with an invalid String' do
          it { expect(subject.has?(invalid_key.to_s)).to be false }
        end

        describe 'with an invalid Symbol' do
          it { expect(subject.has?(invalid_key.to_sym)).to be false }
        end

        describe 'with a valid String', :aggregate_failures do
          it 'should return true' do
            valid_pairs.each_key do |key|
              expect(subject.has?(key.to_s)).to be true
            end
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          it 'should return true' do
            valid_pairs.each_key do |key|
              expect(subject.has?(key.to_sym)).to be true
            end
          end
        end
      end

      describe '#options' do
        include_examples 'should define reader', :options, -> { be_a Hash }

        next unless has_options

        it { expect(provider.options).to be == options }

        context 'when initialized with options' do
          let(:options) { super().merge(custom_option: 'custom value') }

          it { expect(provider.options).to be == options }
        end

        context 'when initialized with read_only: false' do
          let(:options) { super().merge(read_only: false) }

          it { expect(provider.options).to be == options }
        end

        context 'when initialized with read_only: true' do
          let(:options) { super().merge(read_only: true) }

          it { expect(provider.options).to be == options }
        end

        context 'when initialized with write_once: false' do
          let(:options) { super().merge(write_once: false) }

          it { expect(provider.options).to be == options }
        end

        context 'when initialized with write_once: true' do
          let(:options) { super().merge(write_once: true) }

          it { expect(provider.options).to be == options }
        end
      end

      describe '#read_only?' do
        include_examples 'should define predicate', :read_only?

        next unless has_options

        it { expect(provider.read_only?).to be true }

        context 'when initialized with read_only: false' do
          let(:options) { super().merge(read_only: false) }

          it { expect(provider.read_only?).to be false }
        end

        context 'when initialized with read_only: true' do
          let(:options) { super().merge(read_only: true) }

          it { expect(provider.read_only?).to be true }
        end
      end

      describe '#set' do
        let(:invalid_key) { defined?(super()) ? super() : :invalid }

        define_method :call_method do |key|
          subject.set(key, Object.new.freeze)
        end

        it { expect(subject).to respond_to(:set).with(2).arguments }

        include_deferred 'should validate the key'
      end

      describe '#write_once?' do
        include_examples 'should define predicate', :write_once?

        next unless has_options

        it { expect(provider.write_once?).to be false }

        context 'when initialized with write_once: false' do
          let(:options) { super().merge(write_once: false) }

          it { expect(provider.write_once?).to be false }
        end

        context 'when initialized with write_once: true' do
          let(:options) { super().merge(write_once: true) }

          it { expect(provider.write_once?).to be true }
        end
      end
    end

    # Asserts that the object implements the interface for a plural Provider.
    #
    # The following methods must be defined in the example group:
    #
    # - #valid_keys: The valid keys configured for the provider.
    #
    # The behavior can be customized by defining the following methods:
    #
    # - #invalid_key: An example key that does not match the provider. The
    #   default value is :invalid.
    deferred_examples 'should implement the plural Provider interface' \
    do |has_options: true|
      include RSpec::SleepingKingStudios::Deferred::Dependencies

      depends_on :valid_keys, 'the valid keys configured for the provider'

      describe '#set' do
        let(:invalid_key)   { defined?(super()) ? super() : :invalid }
        let(:changed_value) { Object.new.freeze }

        describe 'with an invalid String', :aggregate_failures do
          let(:error_message) do
            "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
          end

          it 'should raise an exception' do
            expect { provider.set(invalid_key.to_s, changed_value) }
              .to raise_error Plumbum::Errors::InvalidKeyError, error_message
          end
        end

        describe 'with an invalid Symbol', :aggregate_failures do
          let(:error_message) do
            "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
          end

          it 'should raise an exception' do
            expect { provider.set(invalid_key.to_sym, changed_value) }
              .to raise_error Plumbum::Errors::InvalidKeyError, error_message
          end
        end

        describe 'with an valid String', :aggregate_failures do
          let(:error_message) do
            "unable to change immutable value for #{provider.class} with key " \
              "#{valid_keys.first.to_s.inspect}"
          end

          it 'should raise an exception' do
            next if valid_keys.empty?

            expect { provider.set(valid_keys.first.to_s, changed_value) }
              .to raise_error Plumbum::Errors::ImmutableError, error_message
          end
        end

        describe 'with an valid Symbol', :aggregate_failures do
          let(:error_message) do
            "unable to change immutable value for #{provider.class} with key " \
              "#{valid_keys.first.to_s.inspect}"
          end

          it 'should raise an exception' do
            next if valid_keys.empty?

            expect { provider.set(valid_keys.first.to_sym, changed_value) }
              .to raise_error Plumbum::Errors::ImmutableError, error_message
          end
        end

        next unless has_options

        context 'when initialized with read_only: false' do
          let(:options) { super().merge(read_only: false) }

          describe 'with an invalid String', :aggregate_failures do
            let(:error_message) do
              "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
            end

            it 'should raise an exception' do
              expect { provider.set(invalid_key.to_s, changed_value) }
                .to raise_error Plumbum::Errors::InvalidKeyError, error_message
            end
          end

          describe 'with an invalid Symbol', :aggregate_failures do
            let(:error_message) do
              "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
            end

            it 'should raise an exception' do
              expect { provider.set(invalid_key.to_sym, changed_value) }
                .to raise_error Plumbum::Errors::InvalidKeyError, error_message
            end
          end

          describe 'with an valid String', :aggregate_failures do
            it 'should update the value' do
              valid_keys.each do |valid_key|
                expect { provider.set(valid_key.to_s, changed_value) }.to(
                  change { provider.get(valid_key) }.to(be == changed_value)
                )
              end
            end
          end

          describe 'with an valid Symbol', :aggregate_failures do
            it 'should update the value' do
              valid_keys.each do |valid_key|
                expect { provider.set(valid_key.to_sym, changed_value) }.to(
                  change { provider.get(valid_key) }.to(be == changed_value)
                )
              end
            end
          end

          context 'when the provider is frozen' do
            let(:error_message) do
              "can't modify frozen #{described_class}: #{provider.inspect}"
            end

            before(:example) { provider.freeze }

            describe 'with an invalid String', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(invalid_key.to_s, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with an invalid Symbol', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(invalid_key.to_sym, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with an valid String', :aggregate_failures do
              it 'should raise an exception' do
                valid_keys.each do |valid_key|
                  expect { provider.set(valid_key.to_s, changed_value) }
                    .to raise_error FrozenError, error_message
                end
              end
            end

            describe 'with an valid Symbol', :aggregate_failures do
              it 'should raise an exception' do
                valid_keys.each do |valid_key|
                  expect { provider.set(valid_key.to_sym, changed_value) }
                    .to raise_error FrozenError, error_message
                end
              end
            end
          end
        end
      end
    end

    # Asserts that the object implements the interface for a singular Provider.
    #
    # The following methods must be defined in the example group:
    #
    # - #valid_key: The valid key configured for the provider.
    #
    # The behavior can be customized by defining the following methods:
    #
    # - #invalid_key: An example key that does not match the provider. The
    #   default value is :invalid.
    deferred_examples 'should implement the singular Provider interface' \
    do |has_options: true, mutable_value: false|
      include RSpec::SleepingKingStudios::Deferred::Dependencies

      depends_on :valid_key, 'the valid key configured for the provider'

      describe '#set' do
        let(:invalid_key)   { defined?(super()) ? super() : :invalid }
        let(:changed_value) { Object.new.freeze }

        describe 'with an invalid String', :aggregate_failures do
          let(:error_message) do
            "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
          end

          it 'should raise an exception' do
            expect { provider.set(invalid_key.to_s, changed_value) }
              .to raise_error Plumbum::Errors::InvalidKeyError, error_message
          end
        end

        describe 'with an invalid Symbol', :aggregate_failures do
          let(:error_message) do
            "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
          end

          it 'should raise an exception' do
            expect { provider.set(invalid_key.to_sym, changed_value) }
              .to raise_error Plumbum::Errors::InvalidKeyError, error_message
          end
        end

        describe 'with an valid String', :aggregate_failures do
          let(:error_message) do
            "unable to change immutable value for #{provider.class} with key " \
              "#{valid_key.to_s.inspect}"
          end

          it 'should raise an exception' do
            expect { provider.set(valid_key.to_s, changed_value) }
              .to raise_error Plumbum::Errors::ImmutableError, error_message
          end
        end

        describe 'with a valid Symbol', :aggregate_failures do
          let(:error_message) do
            "unable to change immutable value for #{provider.class} with key " \
              "#{valid_key.to_s.inspect}"
          end

          it 'should raise an exception' do
            expect { provider.set(valid_key.to_sym, changed_value) }
              .to raise_error Plumbum::Errors::ImmutableError, error_message
          end
        end

        next unless has_options

        context 'when initialized with read_only: false' do
          let(:options) { super().merge(read_only: false) }

          describe 'with an invalid String', :aggregate_failures do
            let(:error_message) do
              "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
            end

            it 'should raise an exception' do
              expect { provider.set(invalid_key.to_s, changed_value) }
                .to raise_error Plumbum::Errors::InvalidKeyError, error_message
            end
          end

          describe 'with an invalid Symbol', :aggregate_failures do
            let(:error_message) do
              "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
            end

            it 'should raise an exception' do
              expect { provider.set(invalid_key.to_sym, changed_value) }
                .to raise_error Plumbum::Errors::InvalidKeyError, error_message
            end
          end

          describe 'with an valid String', :aggregate_failures do
            it 'should update the value' do
              expect { provider.set(valid_key.to_s, changed_value) }.to(
                change { provider.get(valid_key) }.to(be == changed_value)
              )
            end
          end

          describe 'with an valid Symbol', :aggregate_failures do
            it 'should update the value' do
              expect { provider.set(valid_key.to_sym, changed_value) }.to(
                change { provider.get(valid_key) }.to(be == changed_value)
              )
            end
          end

          context 'when the provider is frozen' do
            let(:error_message) do
              "can't modify frozen #{described_class}: #{provider.inspect}"
            end

            before(:example) { provider.freeze }

            describe 'with an invalid String', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(invalid_key.to_s, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with an invalid Symbol', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(invalid_key.to_sym, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with a valid String', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(valid_key.to_s, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with a valid Symbol', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(valid_key.to_sym, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end
          end
        end

        context 'when initialized with write_once: true' do
          let(:options) { super().merge(write_once: true) }

          describe 'with an invalid String', :aggregate_failures do
            let(:error_message) do
              "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
            end

            it 'should raise an exception' do
              expect { provider.set(invalid_key.to_s, changed_value) }
                .to raise_error Plumbum::Errors::InvalidKeyError, error_message
            end
          end

          describe 'with an invalid Symbol', :aggregate_failures do
            let(:error_message) do
              "invalid key #{invalid_key.to_s.inspect} for #{provider.class}"
            end

            it 'should raise an exception' do
              expect { provider.set(invalid_key.to_sym, changed_value) }
                .to raise_error Plumbum::Errors::InvalidKeyError, error_message
            end
          end

          if mutable_value
            describe 'with an valid String', :aggregate_failures do
              it 'should update the value' do
                expect { provider.set(valid_key.to_s, changed_value) }.to(
                  change { provider.get(valid_key) }.to(be == changed_value)
                )
              end
            end

            describe 'with an valid Symbol', :aggregate_failures do
              it 'should update the value' do
                expect { provider.set(valid_key.to_sym, changed_value) }.to(
                  change { provider.get(valid_key) }.to(be == changed_value)
                )
              end
            end
          else
            describe 'with an valid String', :aggregate_failures do
              let(:error_message) do
                "unable to change immutable value for #{provider.class} " \
                  "with key #{valid_key.to_s.inspect}"
              end

              it 'should raise an exception' do
                expect { provider.set(valid_key.to_s, changed_value) }
                  .to raise_error Plumbum::Errors::ImmutableError, error_message
              end
            end

            describe 'with a valid Symbol', :aggregate_failures do
              let(:error_message) do
                "unable to change immutable value for #{provider.class} " \
                  "with key #{valid_key.to_s.inspect}"
              end

              it 'should raise an exception' do
                expect { provider.set(valid_key.to_sym, changed_value) }
                  .to raise_error Plumbum::Errors::ImmutableError, error_message
              end
            end
          end

          context 'when the provider is frozen' do
            let(:error_message) do
              "can't modify frozen #{described_class}: #{provider.inspect}"
            end

            before(:example) { provider.freeze }

            describe 'with an invalid String', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(invalid_key.to_s, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with an invalid Symbol', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(invalid_key.to_sym, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with a valid String', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(valid_key.to_s, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end

            describe 'with a valid Symbol', :aggregate_failures do
              it 'should raise an exception' do
                expect { provider.set(valid_key.to_sym, changed_value) }
                  .to raise_error FrozenError, error_message
              end
            end
          end
        end
      end
    end
  end
end
