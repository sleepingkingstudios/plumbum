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
    deferred_examples 'should implement the Provider interface' do
      include RSpec::SleepingKingStudios::Deferred::Dependencies

      depends_on :valid_pairs,
        'a Hash containing the valid keys the provider should return and the ' \
        'corresponding values.'

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
      end

      describe '#set' do
        let(:invalid_key) { defined?(super()) ? super() : :invalid }

        define_method :call_method do |key|
          subject.set(key, Object.new.freeze)
        end

        it { expect(subject).to respond_to(:set).with(2).arguments }

        include_deferred 'should validate the key'
      end
    end
  end
end
