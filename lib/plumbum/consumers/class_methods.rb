# frozen_string_literal: true

require 'sleeping_king_studios/tools'

require 'plumbum/consumers'

module Plumbum::Consumers
  # Class methods for defining the Consumer interface.
  module ClassMethods # rubocop:disable Metrics/ModuleLength
    UNDEFINED = SleepingKingStudios::Tools::UNDEFINED
    private_constant :UNDEFINED

    class << self # rubocop:disable Metrics/ClassLength
      INVALID_OPTIONS_FOR_METHOD_DEPENDENCY = {
        memoize:   true,
        predicate: false
      }.freeze
      private_constant :INVALID_OPTIONS_FOR_METHOD_DEPENDENCY

      # @api private
      def define_delegated_method( # rubocop:disable Metrics/MethodLength
        receiver,
        key:,
        method_name:,
        path:,
        **options
      )
        validate_delegated_method_options(path:, **options)

        *path, inner_name = path
        method_name       = method_name[1..] if method_name.start_with?('#')
        inner_name        = inner_name[1..]

        dependency_methods_for(receiver)
          .define_method(method_name) do |*args, **keywords, &block|
            inner = get_scoped_plumbum_dependency(key, path:)

            inner.public_send(inner_name, *args, **keywords, &block)
          end # rubocop:disable Style/MultilineBlockChain
          .tap do |method_name|
            receiver.send(:private, method_name) if options[:private]
          end
      end

      # @api private
      def define_memoized_reader( # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
        receiver,
        default:,
        key:,
        method_name:,
        optional:,
        path:,
        **options
      )
        dependency_methods_for(receiver)
          .define_method(method_name) do
            if (@plumbum_dependencies ||= {}).key?(key)
              return @plumbum_dependencies[key]
            end

            get_scoped_plumbum_dependency(key, default:, optional:, path:)
              .tap do |value|
                @plumbum_dependencies[key] = value unless value.nil?
              end
          end # rubocop:disable Style/MultilineBlockChain
          .tap do |method_name|
            receiver.send(:private, method_name) if options[:private]
          end
      end

      # @api private
      def define_methods(receiver, key:, method_name:, memoize:, predicate:, **) # rubocop:disable Metrics/ParameterLists
        define_predicate(receiver, key:, method_name:, **) if predicate

        if memoize
          define_memoized_reader(receiver, key:, method_name:, **)
        else
          define_reader(receiver, key:, method_name:, **)
        end

        method_name.to_sym
      end

      # @api private
      def define_predicate(receiver, key:, method_name:, **options)
        method_name = :"#{method_name}?"

        dependency_methods_for(receiver)
          .define_method(method_name) do
            has_plumbum_dependency?(key)
          end # rubocop:disable Style/MultilineBlockChain
          .tap do |method_name|
            receiver.send(:private, method_name) if options[:private]
          end
      end

      # @api private
      def define_reader( # rubocop:disable Metrics/ParameterLists
        receiver,
        default:,
        key:,
        method_name:,
        optional:,
        path:,
        **options
      )
        dependency_methods_for(receiver)
          .define_method(method_name) do
            get_scoped_plumbum_dependency(key, default:, optional:, path:)
          end # rubocop:disable Style/MultilineBlockChain
          .tap do |method_name|
            receiver.send(:private, method_name) if options[:private]
          end
      end

      # @api private
      def dependency_methods_for(receiver)
        if receiver.const_defined?(:PlumbumDependencyMethods, false)
          return receiver.const_get(:PlumbumDependencyMethods)
        end

        Module
          .new
          .tap { |mod| receiver.include mod }
          .then { |mod| receiver.const_set(:PlumbumDependencyMethods, mod) }
      end

      # @api private
      def split_key(key, as:, scope:)
        ClassMethods.validate_name(key, as: :key)
        ClassMethods.validate_name(scope, as: :scope) if scope

        key = "#{scope}.#{key}" if scope

        segments = key.to_s.split('.')

        return [key, as || key, nil] if segments.size == 1

        [segments.first, as || segments.last, segments[1..]]
      end

      # @api private
      def validate_name(value, as: nil)
        SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .validate_name(value, as:)
      end

      private

      def validate_delegated_method_options(path: nil, **options) # rubocop:disable Metrics/MethodLength
        if path.nil?
          message =
            'delegated methods must have a scope - use a scoped key or pass ' \
            'the :scope option to #dependency'

          raise ArgumentError, message
        end

        INVALID_OPTIONS_FOR_METHOD_DEPENDENCY.each \
        do |option_name, default_value|
          next if options[option_name] == default_value

          raise ArgumentError,
            "invalid option #{option_name.inspect} for method dependency"
        end
      end
    end

    # @overload plumbum_dependency(*keys, as: nil, memoize: true, optional: false, predicate: false, scope: nil)
    #   Defines injected dependencies for instances of the class.
    #
    #   @param keys [Array<String, Symbol>] the keys for the dependency. A new
    #     dependency will be defined for each key using the same options.
    #   @param as [String, Symbol] the method name used to define dependency
    #     methods. Defaults to the key. Cannot be used with multiple keys.
    #   @param default [Object, Proc] if given, the default value will be
    #     returned when the consumer does not have a provider for the
    #     dependency. If the default value is a Proc, the default will be lazily
    #     evaluated in the context of the consumer. A default value *will not*
    #     be returned if a matching provider is defined but does not support the
    #     given scope.
    #   @param memoize [true, false] if true, memoizes the value of the
    #     dependency the first time it is successfully called. Defaults to true.
    #   @param optional [true, false] if true, calling the dependency returns
    #     nil if the dependency is not defined. Defaults to false.
    #   @param predicate [true, false] if true, also defines a predicate method
    #     that returns true if the dependency has a defined value. Defaults to
    #     false.
    #   @param private [true, false] if true, the generated methods will be
    #     generated with private visibility. Defaults to false.
    #   @param scope [String, Symbol] if given, combined with the key or keys to
    #     determine the dependency name and the path from the dependency to the
    #     returned value.
    #
    #   @return [Symbol, Array<Symbol>] the name of the generated method, or the
    #     method names if given more than one key.
    #
    #   @raise [ArgumentError] if any key is not a String or Symbol, or is
    #     empty.
    def plumbum_dependency( # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
      *keys,
      as:        nil,
      default:   UNDEFINED,
      memoize:   true,
      optional:  false,
      predicate: false,
      private:   false,
      scope:     nil
    )
      if keys.size > 1 && as
        raise ArgumentError, 'invalid option :as when providing multiple keys'
      end

      scoped_keys = keys.map do |key|
        define_plumbum_dependency(
          key,
          as:,
          default:,
          memoize:,
          optional:,
          predicate:,
          private:,
          scope:
        )
      end

      scoped_keys.size == 1 ? scoped_keys.first : scoped_keys
    end

    # @param cache [true, false] if false,.clears the memoized value and
    #   recalculates the keys.
    #
    # @return [Set<String>] the keys of the dependencies declared by the class
    #   and its ancestors.
    def plumbum_dependency_keys(cache: true)
      @plumbum_dependency_keys = nil if cache == false

      return @plumbum_dependency_keys if @plumbum_dependency_keys

      @plumbum_dependency_keys = ancestors.reduce(Set.new) do |set, ancestor|
        next set unless ancestor.respond_to?(:own_plumbum_dependency_keys, true)

        set.union(ancestor.own_plumbum_dependency_keys)
      end
    end

    # Registers a provider for the class.
    #
    # @provider [Plumbum::Provider] the provider to register.
    #
    # @return void
    def plumbum_provider(provider) # rubocop:disable Metrics/MethodLength
      unless provider.is_a?(Plumbum::Provider)
        message =
          SleepingKingStudios::Tools::Toolbelt
          .instance
          .assertions
          .error_message_for(
            'sleeping_king_studios.tools.assertions.instance_of',
            as:       :provider,
            expected: Plumbum::Provider
          )

        raise ArgumentError, message
      end

      own_plumbum_providers.prepend(provider)

      nil
    end

    # @param cache [true, false] if false,.clears the memoized value and
    #   reaggregates the providers.
    #
    # @return [Array<Plumbum::Provider>] the providers defined for the class.
    def plumbum_providers(cache: true)
      @plumbum_providers = nil if cache == false

      @plumbum_providers ||= each_plumbum_provider.to_a
    end

    protected

    def own_plumbum_dependency_keys
      @own_plumbum_dependency_keys ||= Set.new
    end

    def own_plumbum_providers
      @own_plumbum_providers ||= []
    end

    private

    def define_plumbum_dependency(key, as: nil, scope: nil, **)
      ClassMethods.validate_name(as, as: :as) unless as.nil?

      key, method_name, path = ClassMethods.split_key(key, as:, scope:)

      own_plumbum_dependency_keys << key.to_s

      if method_name.start_with?('#') || path&.last&.start_with?('#')
        ClassMethods
          .define_delegated_method(self, key:, method_name:, path:, **)
      else
        ClassMethods.define_methods(self, key:, method_name:, path:, **)
      end
    end

    def each_plumbum_provider(&)
      return enum_for(:each_plumbum_provider) unless block_given?

      ancestors.reverse_each do |ancestor|
        next unless ancestor.respond_to?(:own_plumbum_providers, true)

        ancestor.own_plumbum_providers.each(&)
      end
    end
  end
end
