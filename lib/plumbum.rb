# frozen_string_literal: true

# Dependency injection and management library for Ruby.
module Plumbum
  autoload :Provider, 'plumbum/provider'
  autoload :RSpec,    'plumbum/rspec'

  class << self
    # @return [String] the current version of the gem.
    def version
      VERSION
    end
  end
end

require 'plumbum/version'
