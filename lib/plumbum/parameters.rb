# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Utility module that converts constructor parameters to a Provider.
  module Parameters
    # Provider that wraps a subset of the constructor parameters.
    class Provider
      include Plumbum::Providers::Plural

      # @param values [Hash{Symbol=>Object}] the key-value pairs returned by the
      #   provider.
      def initialize(values:)
        @values =
          values
          .transform_keys(&:to_s)
          .freeze
      end
    end

    # @overload initialize(*arguments, **keywords, &block)
    #   @param arguments [Array] the arguments passed to the constructor.
    #   @param keywords [Hash] the keywords passed to the constructor, including
    #     any injected dependencies.
    #   @param block [Proc] the block passed to the constructor.
    def initialize(*, **keywords, &)
      keywords, values = extract_plumbum_dependencies(keywords)

      super

      @plumbum_providers = [
        Plumbum::Parameters::Provider.new(values:),
        *plumbum_providers
      ]
    end

    private

    def extract_plumbum_dependencies(all_keywords)
      keywords = {}
      values   = {}

      all_keywords.each do |key, value|
        hsh      =
          self.class.dependency_keys.include?(key.to_s) ? values : keywords
        hsh[key] = value
      end

      [keywords, values]
    end
  end
end
