# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Namespace for Provider implementations.
  module Providers
    autoload :Global,   'plumbum/providers/global'
    autoload :Singular, 'plumbum/providers/singular'
  end
end
