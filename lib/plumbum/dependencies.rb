# frozen_string_literal: true

require 'plumbum'

module Plumbum
  # Dependencies provide a standard interface that abstracts side effects.
  #
  # Dependency classes wrap side effects such as accessing the file system,
  # reading from or writing to standard IO streams, or performing system
  # commands.
  #
  # Each dependency class also provides a `::Mock` version that isolates that
  # functionality. For example, the file system mock creates an in-memory data
  # structure that simulates reading and writing files without making any
  # changes to the actual file system.
  module Dependencies
    autoload :Clock,         'plumbum/dependencies/clock'
    autoload :FileSystem,    'plumbum/dependencies/file_system'
    autoload :StandardIo,    'plumbum/dependencies/standard_io'
    autoload :SystemCommand, 'plumbum/dependencies/system_command'

    # @return [Plumbum::Provider] the provider for the standard dependencies.
    def self.provider
      @provider ||= Plumbum::ManyProvider.new(
        values: {
          clock:          Clock.new,
          file_system:    FileSystem.new,
          standard_io:    StandardIo.new,
          system_command: SystemCommand.new
        }
      )
    end
  end
end
