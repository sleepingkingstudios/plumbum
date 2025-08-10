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

      describe 'with as: nil' do
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
          expect { described_class.dependency(key, as: Object.new.freeze) }
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
          expect { described_class.dependency(key, as: '') }
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
          expect { described_class.dependency(key, as: :'') }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with as: a String' do
        let(:method_name) { "scoped_#{key}" }
        let(:reader_name) { method_name.to_sym }

        it 'should return the reader name' do
          expect(described_class.dependency(key, as: method_name))
            .to be reader_name
        end

        it 'should add the key to the dependency keys' do
          expect { described_class.dependency(key, as: method_name) }
            .to change(described_class, :dependency_keys)
            .to include(key.to_s)
        end

        it 'should define the reader method', :aggregate_failures do
          expect(instance).not_to respond_to(key)
          expect(instance).not_to respond_to(reader_name)

          described_class.dependency(key, as: method_name)

          expect(instance).not_to respond_to(key)
          expect(instance).to respond_to(reader_name).with(0).arguments
        end
      end

      describe 'with as: a Symbol' do
        let(:method_name) { :"scoped_#{key}" }
        let(:reader_name) { method_name }

        it 'should return the reader name' do
          expect(described_class.dependency(key, as: method_name))
            .to be reader_name
        end

        it 'should add the key to the dependency keys' do
          expect { described_class.dependency(key, as: method_name) }
            .to change(described_class, :dependency_keys)
            .to include(key.to_s)
        end

        it 'should define the reader method', :aggregate_failures do
          expect(instance).not_to respond_to(key)
          expect(instance).not_to respond_to(reader_name)

          described_class.dependency(key, as: method_name)

          expect(instance).not_to respond_to(key)
          expect(instance).to respond_to(reader_name).with(0).arguments
        end
      end

      describe 'with predicate: true' do
        let(:predicate_name) { :"#{reader_name}?" }

        it 'should return the reader name' do
          expect(described_class.dependency(key, predicate: true))
            .to be reader_name
        end

        it 'should add the key to the dependency keys' do
          expect { described_class.dependency(key, predicate: true) }
            .to change(described_class, :dependency_keys)
            .to include(key.to_s)
        end

        it 'should define the predicate method', :aggregate_failures do
          expect(instance).not_to respond_to(predicate_name)

          described_class.dependency(key, predicate: true)

          expect(instance).to respond_to(predicate_name).with(0).arguments
        end

        it 'should define the reader method', :aggregate_failures do
          expect(instance).not_to respond_to(reader_name)

          described_class.dependency(key, predicate: true)

          expect(instance).to respond_to(reader_name).with(0).arguments
        end

        describe 'with as: value' do
          let(:method_name) { :"scoped_#{key}" }
          let(:reader_name) { method_name }

          it 'should define the predicate method', :aggregate_failures do
            expect(instance).not_to respond_to(predicate_name)

            described_class.dependency(key, as: method_name, predicate: true)

            expect(instance).to respond_to(predicate_name).with(0).arguments
          end

          it 'should define the reader method', :aggregate_failures do
            expect(instance).not_to respond_to(reader_name)

            described_class.dependency(key, as: method_name, predicate: true)

            expect(instance).to respond_to(reader_name).with(0).arguments
          end
        end
      end
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:dependency)
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

    context 'when the class defines a dependency with as: value' do
      let(:error_message) do
        'dependency not found with key "railtie"'
      end

      before(:example) do
        described_class.dependency('railtie', as: 'integration')
      end

      it { expect(instance).to respond_to(:integration).with(0).arguments }

      it 'should raise an exception' do
        expect { instance.integration }.to raise_error(
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

        it { expect(instance.integration).to be Spec::RailtieProvider.value }
      end
    end

    context 'when the class defines a dependency with memoize: false' do
      let(:error_message) do
        'dependency not found with key "request"'
      end

      before(:example) do
        described_class.dependency('request', memoize: false)
      end

      it { expect(instance).to respond_to(:request).with(0).arguments }

      it 'should raise an exception' do
        expect { instance.request }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        let(:original_value) { { http_method: :get } }

        example_class 'Spec::MutableProvider', Module do |klass|
          klass.include Plumbum::Providers::Singular

          klass.define_method :initialize do |key:, value:|
            @key   = key.to_s
            @value = value
          end

          klass.attr_writer :value
        end

        example_constant 'Spec::RequestProvider' do
          Spec::MutableProvider.new(key: :request, value: original_value)
        end

        before(:example) do
          described_class.dependency('request', memoize: false)

          described_class.include Spec::RequestProvider
        end

        it { expect(instance.request).to be Spec::RequestProvider.value }

        context 'when the provider value changes' do
          let(:changed_value) { { http_method: :post } }

          before(:example) do
            instance.request # Cache the dependency.

            Spec::RequestProvider.value = changed_value
          end

          it { expect(instance.request).to be Spec::RequestProvider.value }
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

      it { expect(instance).to respond_to(:request).with(0).arguments }

      it 'should raise an exception' do
        expect { instance.request }.to raise_error(
          Plumbum::Errors::MissingDependencyError,
          error_message
        )
      end

      context 'when the class includes a provider for the dependency' do
        let(:original_value) { { http_method: :get } }

        example_class 'Spec::MutableProvider', Module do |klass|
          klass.include Plumbum::Providers::Singular

          klass.define_method :initialize do |key:, value:|
            @key   = key.to_s
            @value = value
          end

          klass.attr_writer :value
        end

        example_constant 'Spec::RequestProvider' do
          Spec::MutableProvider.new(key: :request, value: original_value)
        end

        before(:example) do
          described_class.dependency('request', memoize: true)

          described_class.include Spec::RequestProvider
        end

        it { expect(instance.request).to be Spec::RequestProvider.value }

        context 'when the provider value changes' do
          let(:changed_value) { { http_method: :post } }

          before(:example) do
            instance.request # Cache the dependency.

            Spec::RequestProvider.value = changed_value
          end

          it { expect(instance.request).to be original_value }
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

    context 'when the class includes a mutable provider' do
      let(:original_value) { { http_method: :get } }

      example_class 'Spec::MutableProvider', Module do |klass|
        klass.include Plumbum::Providers::Singular

        klass.define_method :initialize do |key:, value:|
          @key   = key.to_s
          @value = value
        end

        klass.attr_writer :value
      end

      example_constant 'Spec::RequestProvider' do
        Spec::MutableProvider.new(key: :request, value: original_value)
      end

      before(:example) do
        described_class.dependency('request')

        described_class.include Spec::RequestProvider
      end

      it { expect(instance.request).to be Spec::RequestProvider.value }

      context 'when the provider value changes' do
        let(:changed_value) { { http_method: :post } }

        before(:example) do
          instance.request # Cache the dependency.

          Spec::RequestProvider.value = changed_value
        end

        it { expect(instance.request).to be original_value }
      end
    end
  end

  describe '#:dependency?' do
    wrap_deferred 'when the class defines dependencies' do
      it { expect(instance).not_to respond_to(:tools?) }
    end

    context 'when the class defines a dependency with predicate: false' do
      before(:example) do
        described_class.dependency('flag_enabled', predicate: false)
      end

      it { expect(instance).not_to respond_to(:flag_enabled?) }
    end

    context 'when the class defines a dependency with predicate: true' do
      before(:example) do
        described_class.dependency('flag_enabled', predicate: true)
      end

      it { expect(instance).to respond_to(:flag_enabled?).with(0).arguments }

      it { expect(instance.flag_enabled?).to be false }

      context 'with as: value' do
        before(:example) do
          described_class
            .dependency('flag_enabled', as: 'flag', predicate: true)
        end

        it { expect(instance).to respond_to(:flag?).with(0).arguments }

        it { expect(instance.flag?).to be false }

        context 'when the class includes providers' do
          example_class 'Spec::OneProvider', Module do |klass|
            klass.include Plumbum::Providers::Singular

            klass.define_method :initialize do |key:, value:|
              @key   = key.to_s
              @value = value
            end
          end

          example_constant 'Spec::FlagProvider' do
            Spec::OneProvider.new(key: :flag_enabled, value: false)
          end

          before(:example) do
            described_class.include Spec::FlagProvider
          end

          it { expect(instance.flag?).to be true }

          context 'when the class overwrites the method' do # rubocop:disable RSpec/NestedGroups
            before(:example) do
              described_class.define_method(:flag?) do
                super().to_s
              end
            end

            it 'should use the class definition' do
              expect(instance.flag?).to eq 'true'
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
          expect(instance.flag_enabled?).to eq 'false'
        end
      end

      context 'when the class includes providers' do
        example_class 'Spec::OneProvider', Module do |klass|
          klass.include Plumbum::Providers::Singular

          klass.define_method :initialize do |key:, value:|
            @key   = key.to_s
            @value = value
          end
        end

        example_constant 'Spec::FlagProvider' do
          Spec::OneProvider.new(key: :flag_enabled, value: false)
        end

        before(:example) do
          described_class.include Spec::FlagProvider
        end

        it { expect(instance.flag_enabled?).to be true }

        context 'when the class overwrites the method' do
          before(:example) do
            described_class.define_method(:flag_enabled?) do
              super().to_s
            end
          end

          it 'should use the class definition' do
            expect(instance.flag_enabled?).to eq 'true'
          end
        end
      end
    end
  end

  describe '#get_plumbum_dependency' do
    it 'should define the method' do
      expect(instance)
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

  describe '#has_plumbum_dependency?' do
    it 'should define the method' do
      expect(instance).to respond_to(:has_plumbum_dependency?).with(1).argument
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
        expect { instance.has_plumbum_dependency?(nil) }
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
        expect { instance.has_plumbum_dependency?(Object.new.freeze) }
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
        expect { instance.has_plumbum_dependency?('') }
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
        expect { instance.has_plumbum_dependency?(:'') }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a non-matching String' do
      it { expect(instance.has_plumbum_dependency?('invalid')).to be false }
    end

    describe 'with a non-matching Symbol' do
      it { expect(instance.has_plumbum_dependency?(:invalid)).to be false }
    end

    wrap_deferred 'when the class includes providers' do
      describe 'with a non-matching String' do
        it { expect(instance.has_plumbum_dependency?('invalid')).to be false }
      end

      describe 'with a non-matching Symbol' do
        it { expect(instance.has_plumbum_dependency?(:invalid)).to be false }
      end

      describe 'with a matching String' do
        it { expect(instance.has_plumbum_dependency?('tools')).to be true }
      end

      describe 'with a matching Symbol' do
        it { expect(instance.has_plumbum_dependency?(:tools)).to be true }
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
