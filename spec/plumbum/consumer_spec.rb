# frozen_string_literal: true

require 'plumbum/consumer'

RSpec.describe Plumbum::Consumer do
  subject(:instance) { described_class.new(**options) }

  deferred_context 'when the class includes providers' do
    let(:expected_providers) do
      [
        Spec::ToolsProvider,
        Spec::ConfigProvider
      ]
    end

    example_class 'Spec::ManyProvider', Module do |klass|
      klass.include Plumbum::Providers::Plural

      klass.define_method :initialize do |values:|
        tools = SleepingKingStudios::Tools::Toolbelt.instance

        @values = tools.hash_tools.convert_keys_to_strings(values)
      end
    end

    example_class 'Spec::OneProvider', Module do |klass|
      klass.include Plumbum::Providers::Singular

      klass.define_method :initialize do |key:, value:|
        @key   = key.to_s
        @value = value
      end
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
      described_class.include Spec::ConfigProvider
      described_class.include Spec::ToolsProvider
    end
  end

  deferred_context 'when the class defines dependencies' do
    let(:class_dependencies) { %w[env tools] }

    before(:example) do
      described_class.dependency('env')
      described_class.dependency('tools')
    end
  end

  deferred_context 'when the parent class defines dependencies' do
    let(:parent_dependencies) { %w[repository tools] }

    before(:example) do
      parent_class.dependency('repository')
      parent_class.dependency('tools')
    end
  end

  let(:described_class) { Spec::InjectedObject }
  let(:parent_class)    { Spec::InjectedParent }
  let(:options)         { {} }

  define_method :tools do
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  example_class 'Spec::InjectedParent' do |klass|
    klass.include Plumbum::Consumer # rubocop:disable RSpec/DescribedClass
  end

  example_class 'Spec::InjectedObject', 'Spec::InjectedParent'

  describe '.dependency' do
    deferred_examples 'should define the dependency' do
      let(:reader_name) { defined?(super()) ? super() : key.to_sym }

      it { expect(described_class.dependency(key)).to be key.to_sym }

      it 'should add the key to the dependency keys' do
        expect { described_class.dependency(key) }
          .to change(described_class, :dependency_keys)
          .to include(key.to_s)
      end

      it 'should define the reader method', :aggregate_failures do
        expect(instance).not_to respond_to(reader_name)

        described_class.dependency(key)

        expect(instance).to respond_to(reader_name).with(0).arguments
      end
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:dependency)
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
        expect { described_class.dependency(nil) }
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
        expect { described_class.dependency(Object.new.freeze) }
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
        expect { described_class.dependency('') }
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
        expect { described_class.dependency(:'') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a valid String' do
      let(:key) { 'valid' }

      include_deferred 'should define the dependency'
    end

    describe 'with a valid Symbol' do
      let(:key) { :valid }

      include_deferred 'should define the dependency'
    end
  end

  describe '.dependency_keys' do
    it 'should define the class reader' do
      expect(described_class)
        .to define_reader(:dependency_keys)
        .with_value(Set.new)
    end

    wrap_deferred 'when the parent class defines dependencies' do
      let(:expected_dependencies) { parent_dependencies }

      it 'should return the class dependencies' do
        expect(described_class.dependency_keys)
          .to be_a(Set)
          .and match_array(expected_dependencies)
      end
    end

    wrap_deferred 'when the class defines dependencies' do
      let(:expected_dependencies) { class_dependencies }

      it 'should return the class dependencies' do
        expect(described_class.dependency_keys)
          .to be_a(Set)
          .and match_array(expected_dependencies)
      end
    end

    context 'when the parent class and class define dependencies' do
      let(:expected_dependencies) do
        [*parent_dependencies, *class_dependencies].uniq
      end

      include_deferred 'when the parent class defines dependencies'
      include_deferred 'when the class defines dependencies'

      it 'should return the parent class and class dependencies' do
        expect(described_class.dependency_keys)
          .to be_a(Set)
          .and match_array(expected_dependencies)
      end
    end
  end

  describe '.plumbum_providers' do
    it 'should define the class reader' do
      expect(described_class)
        .to define_reader(:plumbum_providers)
        .with_value([])
    end

    wrap_deferred 'when the class includes providers' do
      it { expect(described_class.plumbum_providers).to eq(expected_providers) }
    end
  end

  describe '#:dependency' do
    it { expect(instance).not_to respond_to(:tools) }

    wrap_deferred 'when the class defines dependencies' do
      let(:error_message) do
        'dependency not found with key "tools"'
      end

      it { expect(instance).to respond_to(:tools).with(0).arguments }

      it 'should raise an exception' do
        expect { instance.tools }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      wrap_deferred 'when the class includes providers' do
        it { expect(instance.tools).to be Spec::ToolsProvider.value }

        context 'when the class overwrites the method' do
          before(:example) do
            described_class.define_method(:tools) do
              { tools: super() }
            end
          end

          it 'should use the class definition' do
            expect(instance.tools).to eq({ tools: Spec::ToolsProvider.value })
          end
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

      it { expect(instance).to respond_to(:railtie).with(0).arguments }

      it 'should raise an exception' do
        expect { instance.railtie }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        example_class 'Spec::OneProvider', Module do |klass|
          klass.include Plumbum::Providers::Singular

          klass.define_method :initialize do |key:, value:|
            @key   = key.to_s
            @value = value
          end
        end

        example_constant 'Spec::RailtieProvider' do
          Spec::OneProvider.new(key: :railtie, value: Object.new.freeze)
        end

        before(:example) do
          described_class.include Spec::RailtieProvider
        end

        it { expect(instance.railtie).to be Spec::RailtieProvider.value }
      end
    end

    context 'when the class defines a dependency with optional: true' do
      before(:example) do
        described_class.dependency('railtie', optional: true)
      end

      it { expect(instance).to respond_to(:railtie).with(0).arguments }

      it { expect(instance.railtie).to be nil }

      context 'when the class includes a provider for the dependency' do
        example_class 'Spec::OneProvider', Module do |klass|
          klass.include Plumbum::Providers::Singular

          klass.define_method :initialize do |key:, value:|
            @key   = key.to_s
            @value = value
          end
        end

        example_constant 'Spec::RailtieProvider' do
          Spec::OneProvider.new(key: :railtie, value: Object.new.freeze)
        end

        before(:example) do
          described_class.include Spec::RailtieProvider
        end

        it { expect(instance.railtie).to be Spec::RailtieProvider.value }
      end
    end
  end

  describe '#get_plumbum_dependency' do
    it 'should define the method' do
      expect(instance).to respond_to(:get_plumbum_dependency).with(1).argument
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
        expect { instance.get_plumbum_dependency(nil) }
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
        expect { instance.get_plumbum_dependency(Object.new.freeze) }
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
        expect { instance.get_plumbum_dependency('') }
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
        expect { instance.get_plumbum_dependency(:'') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a non-matching String' do
      let(:error_message) do
        'dependency not found with key "invalid"'
      end

      it 'should raise an exception' do
        expect { instance.get_plumbum_dependency('invalid') }.to raise_error(
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
        expect { instance.get_plumbum_dependency(:invalid) }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end
    end

    wrap_deferred 'when the class includes providers' do
      describe 'with a non-matching String' do
        let(:error_message) do
          'dependency not found with key "invalid"'
        end

        it 'should raise an exception' do
          expect { instance.get_plumbum_dependency('invalid') }.to raise_error(
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
          expect { instance.get_plumbum_dependency(:invalid) }.to raise_error(
            Plumbum::Errors::MissingDependencyError,
            error_message
          )
        end
      end

      describe 'with a matching String' do
        it 'should return the dependency value' do
          expect(instance.get_plumbum_dependency('env'))
            .to eq(Spec::ConfigProvider.values['env'])
        end

        context 'with a String matching multiple providers' do
          it 'should return the value from the last provider' do
            expect(instance.get_plumbum_dependency('tools'))
              .to eq(Spec::ToolsProvider.value)
          end
        end
      end

      describe 'with a matching Symbol' do
        it 'should return the dependency value' do
          expect(instance.get_plumbum_dependency(:env))
            .to eq(Spec::ConfigProvider.values['env'])
        end

        context 'with a Symbol matching multiple providers' do
          it 'should return the value from the last provider' do
            expect(instance.get_plumbum_dependency(:tools))
              .to eq(Spec::ToolsProvider.value)
          end
        end
      end
    end
  end

  describe '#plumbum_providers' do
    include_examples 'should define reader', :plumbum_providers, []

    wrap_deferred 'when the class includes providers' do
      it { expect(instance.plumbum_providers).to eq(expected_providers) }
    end
  end
end
