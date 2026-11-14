# frozen_string_literal: true

require 'cuprum/error'

require 'plumbum/errors'

module Plumbum::Errors
  # Error returned when a system command returns a non-success status.
  class SystemCommandFailure < Cuprum::Error
    # Short string used to identify the type of error.
    TYPE = 'cuprum.cli.errors.system_command_failure'

    # @param command [String] the failed command.
    # @param details [String] the error output from the process, if any.
    # @param exit_status [Integer] the exit code returned by the process.
    def initialize(command:, details: nil, exit_status: nil)
      @command     = command
      @details     = details
      @exit_status = exit_status

      super(message: default_message)
    end

    attr_reader :command

    attr_reader :details

    attr_reader :exit_status

    private

    def as_json_data
      {
        'command'     => command,
        'details'     => details,
        'exit_status' => exit_status
      }
    end

    def default_message
      %(system command failed with exit status #{exit_status} - "#{command}")
    end
  end
end
