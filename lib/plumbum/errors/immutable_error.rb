# frozen_string_literal: true

require 'plumbum/errors'

module Plumbum::Errors
  # Exception raised when attempting to change an immutable value.
  class ImmutableError < StandardError; end
end
