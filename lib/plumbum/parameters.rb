# frozen_string_literal: true

require 'plumbum'
require 'plumbum/many_provider'

module Plumbum
  # Utility module that converts constructor parameters to a Provider.
  module Parameters
    # @overload initialize(*arguments, **keywords, &block)
    #   @param arguments [Array] the arguments passed to the constructor.
    #   @param keywords [Hash] the keywords passed to the constructor, including
    #     any injected dependencies.
    #   @param block [Proc] the block passed to the constructor.
    def initialize(*, **keywords, &)
      values, keywords = extract_plumbum_dependencies(keywords)

      super

      @plumbum_parameters_provider = Plumbum::ManyProvider.new(values:)
    end

    private

    def extract_plumbum_dependencies(keywords)
      dependency_keys = self.class.dependency_keys

      keywords
        .partition { |key, _| dependency_keys.include?(key.to_s) }
        .map(&:to_h)
    end

    def plumbum_providers
      [
        @plumbum_parameters_provider,
        *super
      ]
    end
  end
end
