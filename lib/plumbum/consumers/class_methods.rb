# frozen_string_literal: true

require 'plumbum/consumers'

module Plumbum::Consumers
  # Class methods for defining the Consumer interface.
  module ClassMethods
    class << self
      # @api private
      def define_memoized_reader(receiver, key:, method_name:, optional:, path:)
        dependency_methods_for(receiver).define_method(method_name) do
          if (@plumbum_dependencies ||= {}).key?(key)
            return @plumbum_dependencies[key]
          end

          get_scoped_plumbum_dependency(key, optional:, path:).tap do |value|
            @plumbum_dependencies[key] = value unless value.nil?
          end
        end
      end

      # @api private
      def define_methods(receiver, key:, method_name:, memoize:, predicate:, **) # rubocop:disable Metrics/ParameterLists
        define_predicate(receiver, key:, method_name:) if predicate

        if memoize
          define_memoized_reader(receiver, key:, method_name:, **)
        else
          define_reader(receiver, key:, method_name:, **)
        end

        method_name.to_sym
      end

      # @api private
      def define_predicate(receiver, key:, method_name:)
        method_name = :"#{method_name}?"

        dependency_methods_for(receiver).define_method(method_name) do
          has_plumbum_dependency?(key)
        end
      end

      # @api private
      def define_reader(receiver, key:, method_name:, optional:, path:)
        dependency_methods_for(receiver).define_method(method_name) do
          get_scoped_plumbum_dependency(key, optional:, path:)
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
      def split_key(key, as:)
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
    end

    # Defines an injected dependency for instances of the class.
    #
    # @param key [String, Symbol] the key for the dependency.
    # @param as [String, Symbol] the method name used to define dependency
    #   methods. Defaults to the key.
    # @param memoize [true, false] if true, memoizes the value of the
    #   dependency the first time it is successfully called. Defaults to true.
    # @param optional [true, false] if true, calling the dependency returns
    #   nil if the dependency is not defined. Defaults to false.
    # @param predicate [true, false] if true, also defines a predicate method
    #   that returns true if the dependency has a defined value. Defaults to
    #   false.
    #
    # @return [Symbol] the name of the generated method.
    #
    # @raise [ArgumentError] if the key is not a String or Symbol, or is
    #   empty.
    def plumbum_dependency( # rubocop:disable Metrics/MethodLength
      key,
      as:        nil,
      memoize:   true,
      optional:  false,
      predicate: false
    )
      ClassMethods.validate_name(key, as: :key)
      ClassMethods.validate_name(as,  as: :as) unless as.nil?

      key, method_name, path = ClassMethods.split_key(key, as:)

      plumbum_dependency_keys << key.to_s

      ClassMethods.define_methods(
        self,
        key:,
        method_name:,
        memoize:,
        optional:,
        path:,
        predicate:
      )
    end

    # @return [Set<String>] the keys of the dependencies declared by the class
    #   and its ancestors.
    def plumbum_dependency_keys
      return @plumbum_dependency_keys if @plumbum_dependency_keys

      @plumbum_dependency_keys =
        if superclass.respond_to?(:plumbum_dependency_keys)
          superclass.plumbum_dependency_keys.dup
        else
          Set.new
        end
    end
  end
end
