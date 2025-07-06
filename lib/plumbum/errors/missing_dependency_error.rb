# frozen_string_literal: true

require 'plumbum/errors'

module Plumbum::Errors
  # Exception raised when attempting to retrieve a missing dependency.
  class MissingDependencyError < StandardError; end
end
