# frozen_string_literal: true

# Dependency injection and management library for Ruby.
module Plumbum
  autoload :Consumer,     'plumbum/consumer'
  autoload :Consumers,    'plumbum/consumers'
  autoload :Errors,       'plumbum/errors'
  autoload :ManyProvider, 'plumbum/many_provider'
  autoload :OneProvider,  'plumbum/one_provider'
  autoload :Parameters,   'plumbum/parameters'
  autoload :Provider,     'plumbum/provider'
  autoload :Providers,    'plumbum/providers'

  # Object representing an undefined or uninitialized value.
  UNDEFINED = Object.new.freeze

  # @return [String] the absolute path to the gem directory.
  def self.gem_path
    sep     = File::SEPARATOR
    pattern = /#{sep}lib#{sep}?\z/

    __dir__.sub(pattern, '')
  end

  # @return [String] the current version of the gem.
  def self.version
    VERSION
  end
end

require 'plumbum/version'
