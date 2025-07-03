# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Namespace for Provider implementations.
  module Providers
    autoload :Global,   'plumbum/providers/global'
    autoload :Plural,   'plumbum/providers/plural'
    autoload :Singular, 'plumbum/providers/singular'
  end
end
