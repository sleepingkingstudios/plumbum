# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Namespace for exceptions raised when handling Plumbum errors.
  module Errors
    autoload :ImmutableError,         'plumbum/errors/immutable_error'
    autoload :InvalidDependencyError, 'plumbum/errors/invalid_dependency_error'
    autoload :InvalidKeyError,        'plumbum/errors/invalid_key_error'
    autoload :MissingDependencyError, 'plumbum/errors/missing_dependency_error'
  end
end
