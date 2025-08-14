# frozen_string_literal: true

require 'plumbum/errors'

module Plumbum::Errors
  # Exception raised when attempting to set an invalid key for a provider.
  class InvalidKeyError < StandardError; end
end
