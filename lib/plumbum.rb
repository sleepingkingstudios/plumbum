# frozen_string_literal: true

# Dependency injection and management library for Ruby.
module Plumbum
  autoload :Errors,    'plumbum/errors'
  autoload :Provider,  'plumbum/provider'
  autoload :Providers, 'plumbum/providers'

  class << self
    # @return [String] the current version of the gem.
    def version
      VERSION
    end
  end
end

require 'plumbum/version'
