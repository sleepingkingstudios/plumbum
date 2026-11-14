# frozen_string_literal: true

require 'open3'

require 'plumbum/dependencies'
require 'plumbum/errors/system_command_failure'

module Plumbum::Dependencies
  # Utility wrapper for running system command and capturing output.
  class SystemCommand
    # Data object representing the captured output and status of a process.
    CapturedOutput = Data.define(:error, :output, :status) do
      # @return [true, false] true if the process was successful, otherwise
      #   false.
      def success? = status.success?
    end

    # @overload capture(command,.arguments: [], environment: {}, options: {})
    #   Executes the system command and returns the captured output.
    #
    #   @param command [String] the command to run.
    #   @param arguments [Array<String>] command-line flags or arguments to pass
    #     to the command.
    #   @param enviroment [Hash<String, Object>] environment variables to set
    #     for the command.
    #   @param options [Hash<String, Object>] command line options and values to
    #     pass to the command.
    #
    #   @return [Cuprum::Result<Plumbum::Dependencies::SystemCommand::CapturedOutput>]
    #     a Result wrapping the process status and captured output. The Result
    #     will have a status of :success if the process ran successfully;
    #     otherwise, the Result will have a status of :failure
    def capture(command, **)
      value = capture_command(command, **)

      return Cuprum::Result.new(value:) if value.success?

      error = Plumbum::Errors::SystemCommandFailure.new(
        command:,
        details:     value.error,
        exit_status: value.status.exitstatus
      )

      Cuprum::Result.new(error:, value:)
    end

    # @overload spawn(command, arguments: [], enviroment:, options: {})
    #   Spawns a process to run the system command.
    #
    #   @param command [String] the command to run.
    #   @param arguments [Array<String>] command-line flags or arguments to pass
    #     to the command.
    #   @param enviroment [Hash<String, Object>] environment variables to set
    #     for the command.
    #   @param options [Hash<String, Object>] command line options and values to
    #     pass to the command.
    #
    #   @return [Cuprum::Result<nil>] a result with status :success if the
    #     process ran successfully; otherwise, a result with status :failure and
    #     an Error.
    def spawn(command, **)
      status = spawn_command(command, **)

      return Cuprum::Result.new if status.success?

      error = Plumbum::Errors::SystemCommandFailure.new(
        command:,
        exit_status: status.exitstatus
      )

      Cuprum::Result.new(error:)
    end

    private

    def blank?(value)
      value.nil? || (value.respond_to?(:empty?) && value.empty?)
    end

    def build_command(command, arguments: nil, environment: nil, options: nil)
      # @todo [RUBY_VERSION <= '3.3'] remove || {} fallbacks.
      [
        format_environment(**(environment || {})),
        command,
        format_arguments(*arguments),
        format_options(**(options || {}))
      ]
        .reject { |value| value.nil? || value.empty? }
        .join(' ')
    end

    def capture_command(command, **)
      command = build_command(command, **)

      output, error, status = Open3.capture3(command)

      CapturedOutput.new(output:, error:, status:)
    end

    def format_arguments(*arguments)
      arguments.join(' ')
    end

    def format_environment(**environment)
      environment
        .reject { |_, value| blank?(value) }
        .map do |key, value|
          key = tools.string_tools.underscore(key.to_s).upcase

          "#{key}=#{value.inspect}"
        end
        .join(' ')
    end

    def format_options(**options) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength
      options
        .reject { |_, value| blank?(value) }
        .map do |key, value|
          next if value.nil? || (value.respond_to?(:empty?) && value.empty?)

          key   = key.to_s
          value = value.inspect

          next "#{key}=#{value}" if key.start_with?('-')

          key = tools.string_tools.underscore(key).tr('_', '-')

          "#{key.length == 1 ? '-' : '--'}#{key}=#{value}"
        end
        .join(' ')
    end

    def spawn_command(command, **)
      command   = build_command(command, **)
      pid       = Process.spawn(command)
      _, status = Process.wait2(pid)

      status
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
