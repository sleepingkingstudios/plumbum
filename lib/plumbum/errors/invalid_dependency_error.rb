# frozen_string_literal: true

require 'plumbum/errors'

module Plumbum::Errors
  # Exception raised when a dependency exists but cannot be resolved.
  class InvalidDependencyError < StandardError; end
end
